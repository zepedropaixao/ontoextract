package OntoExtract::Controller::Role;
use Moose;
use namespace::autoclean;
use Time::Local;
use utf8;
use POSIX;
BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

OntoExtract::Controller::Role - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base : Chained('/'): PathPart('role'): CaptureArgs(0) {
my ($self, $c) = @_;
my $rs = $c->model('OntoExtract::Role')->search( {}, { page => 1, rows => 10, order_by => 'name', group_by => 'name' });
my $role_pager = $rs->pager;
my $total_role = $role_pager->total_entries;
$c->stash(total_role_rs => $total_role);
$c->stash(role_res_nr => $rs->page(1));
$c->stash(role_rs => $c->model('OntoExtract::Role'));
$c->stash(certainty_rs => $c->model('OntoExtract::Certainty'));
}

sub search : Chained('base'): PathPart('search'): Args(0) {
	my ($self, $c) = @_;
	if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
	$c->stash->{'template'} = 'role/list.tt';
	if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;
	my $searchq = $params->{searchquery};
	my @search_rs =  $c->model('OntoExtract::Role')->search( { name => { like => '%'.$searchq.'%' } } , { order_by => 'name'});
	
	return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('results'),[ 0 ]),$c->stash(role_res_nr => \@search_rs) );
}
}

sub add : Chained('base'): PathPart('add'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}

my $resper = $c->model('OntoExtract::Person')->search( {}, { order_by => 'name' });
$c->stash(per_res_nr => $resper);
my $resorg = $c->model('OntoExtract::Organization')->search( {}, { order_by => 'name' });
$c->stash(org_res_nr => $resorg);

if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;

	## Retrieve the role_rs stashed by the base action:
	my $role_rs = $c->stash->{role_rs};
	my $certainty_rs = $c->stash->{certainty_rs};
   

	## Create the role:
	my $newrole = eval { $role_rs->create({		
	name => $params->{name},
	abstract => $params->{abstract},
	articlelink => $params->{articlelink},
	incompleteflag => $params->{incompleteflag}
	}) };
	foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $newrole->update({
			$key => "v"
		});
	 
	 } 
	}
		
	if($params->{id_person} ne '') {
		$newrole->update({
		id_person => $params->{id_person}
	});
	}
	if($params->{id_organization} ne '') {
		$newrole->update({
		id_organization => $params->{id_organization}
	});
	}
	 if($params->{startdate} ne '' && $params->{startdate} ne "0000-00-00" ) {
		$newrole->update({
		startdate => $params->{startdate}
	});
	}
	if($params->{enddate} ne '' && $params->{enddate} ne "0000-00-00" ) {
		$newrole->update({
		enddate => $params->{enddate}
	});
	}
	
	my $newcertainty = eval { $certainty_rs->create({
	id_to => $newrole->id_role,
	to_flag => 'r',
	method_certainty => 0,
	final_certainty => 100,
	nr_hits => 0
	}) };
	
	if($params->{type} eq 'p')
	{
		return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $params->{id_person} ]) );
	}
	if($params->{type} eq 'o')
	{
		return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $params->{id_organization} ]) );
	}

	## Send the role to view the newly created role
	return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('profile'),[ $newrole->id_role ]) );
}
}

sub list : Chained('base') :PathPart(''): CaptureArgs(1) {
my($self, $c, $rolepagein) = @_;

$c->stash->{'rolepage'} = $rolepagein;

}

sub results : Chained('list') :PathPart('list'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
  $c->stash->{template} = "role/list.tt";
}

sub role : Chained('base'): PathPart(''): CaptureArgs(1) {
my ($self, $c, $roleid) = @_;
if($roleid =~ /\D/) {
die "Misuse of URL, userid does not contain only digits!";
}

my $role = $c->stash->{role_rs}->find({ id_role => $roleid },
				{ key => 'primary' });
	die "No such role" if(!$role);
	$c->stash(role => $role);
}

sub history : Chained('role') :PathPart('history'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}
my $role = $c->stash->{role};
my $id = $role->id_role;
	
my $elem = $c->model('OntoExtract::Certainty')->find( {id_to => $id, to_flag => 'r'});


my %others =   ( fontname => 'Courier', fontsize => 9);
my %me = ( fontname => 'Courier', fontsize => 9, color => 'red', fontcolor => 'red' );   

my $g = GraphViz->new(
   rankdir => 1,        # Left to right instead of top to bottom.
);
my $back = $elem;
my $while_flag = 1;
while($while_flag){
	if(defined($back->id_from)){
		my $to = get_name($self,$c,$back->id_to,$back->to_flag);
		my $from = get_name($self,$c,$back->id_from,$back->from_flag);
		if($back->id_to == $id && $back->to_flag eq 'r'){
			$g->add_node($to, %me);
		}else {
			$g->add_node($to, %others);
		}
	
	$g->add_node($from, %others);
	$g->add_edge($from => $to);
	$back = $c->model('OntoExtract::Certainty')->find({ id_to => $elem->id_from, to_flag => $elem->from_flag });
	if(!defined($back->id_from)){
		$while_flag = 0;
	}
} else {
	my $to = get_name($self,$c,$back->id_to,$back->to_flag);
	if($back->id_to == $id && $back->to_flag eq 'r'){
			$g->add_node($to, %me);
		}else {
			$g->add_node($to, %others);
		}
	$while_flag = 0;
}
}

my @history = get_tree_leafs($self, $c, ($elem));
foreach my $nod (@history){
	if($nod->to_flag eq 'p' || $nod->to_flag eq 'o' || $nod->to_flag eq 'r'){
	my $to = get_name($self,$c,$nod->id_to,$nod->to_flag);
	$g->add_node($to, %others);
}
}
foreach my $nod (@history){
	if($nod->to_flag eq 'p' || $nod->to_flag eq 'o' || $nod->to_flag eq 'r'){
	my $to = get_name($self,$c,$nod->id_to,$nod->to_flag);
	my $from = get_name($self,$c,$nod->id_from,$nod->from_flag);
	if($from ne $to){
	$g->add_edge($from => $to);
}
}
}

open (PNG, ">../root/static/images/trees/".$id."_r.png");
print PNG $g->as_png;
close PNG;	
	
	
}

sub profile : Chained('role') :PathPart('profile'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}


$c->stash(time_converter => sub { my ($hour,$min,$sec,$day,$month,$year) = @_;
my @today = localtime();
my $time = timelocal(@today);
my @birthday = ($hour,$min,$sec,$day,$month,$year);
my $birthtime = timelocal(@birthday);
my $time_calculated = ($time - $birthtime);
my $return_string = "$time_calculated sec(s)";
if($time_calculated > 60) {
	$time_calculated = sprintf("%d",($time_calculated / 60));
	$return_string = "$time_calculated min(s)";
}
if($time_calculated > 60) {
	$time_calculated = sprintf("%d",($time_calculated / 60));
	$return_string = "$time_calculated hour(s)";
	if($time_calculated > 24) {
		$time_calculated = sprintf("%d",($time_calculated / 24));
		$return_string = "$time_calculated day(s)";
	}
}
if($time_calculated > 365) {
	$time_calculated = sprintf("%d",($time_calculated / 365));
	$return_string = "$time_calculated year(s)";
}
return $return_string;
});

$c->stash(get_certainty => sub { my ($id,$type) = @_;
my $rs = $c->model('OntoExtract::Certainty')->find( {id_to => $id, to_flag => $type});
return $rs->final_certainty, $rs->nr_hits;
});


my $role = $c->stash->{role};
my $relpage;
my $refpage;
my $nickpage;
my $show_all_per = 0;
my $show_all_org = 0;
my $show_edit = 0;
if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;
	$relpage = $params->{relpage};
	$refpage = $params->{refpage};
	$nickpage = $params->{nickpage};
	$show_all_per = $params->{show_all_per};
	$show_all_org = $params->{show_all_org};
	$show_edit = $params->{show_edit};
}
$relpage = 1 if(!$relpage);
$refpage = 1 if(!$refpage);
$nickpage = 1 if(!$nickpage);
$show_all_per = 0 if(!$show_all_per);
$show_all_org = 0 if(!$show_all_org);
$show_edit = 0 if(!$show_edit);
$c->stash(show_edit => $show_edit);

my $relres = $c->model('OntoExtract::Relatedurl')->search( {fromwho_id => $role->id_role, fromwho_flag => 'r', type_flag => 'r'}, { page => 1, rows => 5 });
my $rel_pager = $relres->pager;
my $total_rel = $rel_pager->total_entries;
$c->stash(relpage => $relpage);
$c->stash(total_rel_rs => $total_rel);
$c->stash(rel_res_nr => $relres);


my $refres = $c->model('OntoExtract::Relatedurl')->search( {fromwho_id => $role->id_role, fromwho_flag => 'r', type_flag => 'b'}, { page => 1, rows => 5 });
my $ref_pager = $refres->pager;
my $total_ref = $ref_pager->total_entries;
$c->stash(refpage => $refpage);
$c->stash(total_ref_rs => $total_ref);
$c->stash(ref_res_nr => $refres);

my $nickres = $c->model('OntoExtract::NickName')->search( {fromwho_id => $role->id_role, fromwho_flag => 'r'}, { page => 1, rows => 5, order_by => 'name' });
my $nick_pager = $nickres->pager;
my $total_nick = $nick_pager->total_entries;
$c->stash(nickpage => $nickpage);
$c->stash(total_nick_rs => $total_nick);
$c->stash(nick_res_nr => $nickres);




my $person_assoc = $c->model('OntoExtract::Person')->find($role->id_person);
$c->stash(person_assoc => $person_assoc);
my $organization_assoc = $c->model('OntoExtract::Organization')->find($role->id_organization);
$c->stash(organization_assoc => $organization_assoc);

my $resper = $c->model('OntoExtract::Person')->search( {}, {page => 1, rows => 10, order_by => 'name' });
$c->stash(per_res_nr => $resper);
my $resorg = $c->model('OntoExtract::Organization')->search( {}, {page => 1, rows => 10, order_by => 'name' });
$c->stash(org_res_nr => $resorg);

if($show_all_per == 1){
	my $resper = $c->model('OntoExtract::Person')->search( {}, { order_by => 'name' });
	$c->stash(per_res_nr => $resper);
}
if($show_all_org == 1){
	my $resorg = $c->model('OntoExtract::Organization')->search( {}, { order_by => 'name' });
	$c->stash(org_res_nr => $resorg);
}

}

sub del : Chained('role') :PathPart('del'): Args(0) {
my ( $self, $c ) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to delete any role." ;
	return;
}	
my $role = $c->stash->{role};
my $name = $c->stash->{role}->name;
my $iddel = $c->stash->{role}->id_role;
 $c->stash->{template} = "role/list.tt";
 my @relatedurl =  $c->model('OntoExtract::RelatedURL')->search( { fromwho_id => $iddel, fromwho_flag => 'r' });
 my @nicknames =  $c->model('OntoExtract::NickName')->search( { fromwho_id => $iddel, fromwho_flag => 'r' });
  my $certainty = $c->model('OntoExtract::Certainty')->find({id_to => $iddel, to_flag => 'r'});

my @history =  get_tree_leafs($self, $c, ($certainty));
 if($c->user_exists() && ($c->user->role eq 'admin' || $c->user->role eq 'operator')) {


foreach my $hist (@history)
	{

		my $elem = get_element($self, $c, $hist->id_to, $hist->to_flag);
		if(defined($elem)){
		$elem->delete();
	}
		my @elem_relatedurl =  $c->model('OntoExtract::RelatedURL')->search( { fromwho_id => $hist->id_to, fromwho_flag => $hist->to_flag });
		my @elem_nicknames =  $c->model('OntoExtract::NickName')->search( { fromwho_id => $hist->id_to, fromwho_flag => $hist->to_flag });
		foreach my $resrel (@elem_relatedurl)
		{
				my $cert = $c->model('OntoExtract::Certainty')->find({id_to => $resrel->id_relatedurl, to_flag => 'u'});
				$cert->delete();
				$resrel->delete();
		}
		foreach my $nicks (@elem_nicknames)
		{
				my $cert = $c->model('OntoExtract::Certainty')->find({id_to => $nicks->id_nickname, to_flag => 'n'});
				$cert->delete();
				$nicks->delete();
		}
		if($hist->to_flag eq 'p'){
			my @elem_roles =  $c->model('OntoExtract::Role')->search( { id_person => $hist->id_to });
			foreach my $rolex (@elem_roles)
			{
				 $rolex->update({
				id_person => undef
			});
			}
		}
		if($hist->to_flag eq 'o'){
			my @elem_roles =  $c->model('OntoExtract::Role')->search( { id_organization => $hist->id_to });
			foreach my $rolex (@elem_roles)
			{
				 $rolex->update({
				id_organization => undef
			});
			}
		}
		
		$hist->delete(); 
	}


foreach my $resrel (@relatedurl)
	{
		my $cert = $c->model('OntoExtract::Certainty')->find({id_to => $resrel->id_relatedurl, to_flag => 'u'});
		 $cert->delete();
		 $resrel->delete();
	}
foreach my $nicks (@nicknames)
	{
		my $cert = $c->model('OntoExtract::Certainty')->find({id_to => $nicks->id_nickname, to_flag => 'n'});
		 $cert->delete();
		 $nicks->delete();
	}
	
	$certainty->delete();
$role->delete();
my @res = $c->model('OntoExtract::Role')->all;
$c->stash(role_res_nr => \@res);

return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('results'),[0]),$c->stash->{'message'} = "You have eliminated role $name" );
}

return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('results'),[0]),$c->stash->{'message'} = "You don't have permission to delete $name" );


}

sub edit : Chained('role') :PathPart('edit'): Args(0) {
my ($self, $c) = @_;

if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	

if(lc $c->req->method eq 'post') {
my $params = $c->req->params;
my $role = $c->stash->{role};
my $id_role = $c->stash->{role}->id_role;

## Update role
$role->update({
	id_person => $params->{id_person},
	id_organization => $params->{id_organization},
	name => $params->{name},
	abstract => $params->{abstract},
	articlelink => $params->{articlelink},
	incompleteflag => $params->{incompleteflag},
	name_valid => "",
	startdate_valid => "",
	enddate_valid => "",
	abstract_valid => "",
	articlelink_valid => ""
		});
		
	foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $role->update({
			$key => "v"
		});
		if($key eq "name_valid"){
			my $certainty = $c->model('OntoExtract::Certainty')->find( {id_to => $id_role, to_flag => 'r'});
			$certainty->update({
				final_certainty => "100"				
				});
			my $now = strftime("%Y/%m/%d - %R", localtime(time));
			my $out_file = ">>../script/logs/validation/". $c->user->name ."_".$c->user->role.".txt";
			open (EDITLOG, $out_file);
			print (EDITLOG "[$now] - validation of Role: ".$role->name ."\n");
			close (EDITLOG);
		}
		
	 
	 } 
	}
	
		if($params->{id_person} eq '') {
		$role->update({
		id_person => undef
	});
	}
	if($params->{id_organization} eq '') {
		$role->update({
		id_organization => undef
	});
	}
	
	 if($params->{startdate} ne '' && $params->{startdate} ne "0000-00-00" ) {
		$role->update({
		startdate => $params->{startdate}
	});
	}
	if($params->{enddate} ne '' && $params->{enddate} ne "0000-00-00" ) {
		$role->update({
		enddate => $params->{enddate}
	});
	}
		
## Send the role back to the changed profile
return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('profile'),[ $role->id_role ]) );
}
}

sub delbyid : Chained('base') :PathPart('delbyid'): Args(0) {
my ( $self, $c ) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to delete any role." ;
	return;
}


if(lc $c->req->method eq 'post') {
my $params = $c->req->params;
my $role =  $c->model('OntoExtract::Role')->search( { id_role => $params->{id_role} });
my $idred = $params->{idredir};
 my @relatedurl =  $c->model('OntoExtract::RelatedURL')->search( { fromwho_id =>  $params->{id_role}, fromwho_flag => 'r' });
 my @nicknames =  $c->model('OntoExtract::NickName')->search( { fromwho_id =>  $params->{id_role}, fromwho_flag => 'r' });
 my $certainty = $c->model('OntoExtract::Certainty')->find({id_to => $params->{id_role}, to_flag => 'r'});
 if($c->user_exists() && ($c->user->role eq 'admin' || $c->user->role eq 'operator')) {


my @history =  get_tree_leafs($self, $c, ($certainty));
foreach my $hist (@history)
	{

		my $elem = get_element($self, $c, $hist->id_to, $hist->to_flag);
		if(defined($elem)){
		$elem->delete();
	}
		my @elem_relatedurl =  $c->model('OntoExtract::RelatedURL')->search( { fromwho_id => $hist->id_to, fromwho_flag => $hist->to_flag });
		my @elem_nicknames =  $c->model('OntoExtract::NickName')->search( { fromwho_id => $hist->id_to, fromwho_flag => $hist->to_flag });
		foreach my $resrel (@elem_relatedurl)
		{
				my $cert = $c->model('OntoExtract::Certainty')->find({id_to => $resrel->id_relatedurl, to_flag => 'u'});
				$cert->delete();
				$resrel->delete();
		}
		foreach my $nicks (@elem_nicknames)
		{
				my $cert = $c->model('OntoExtract::Certainty')->find({id_to => $nicks->id_nickname, to_flag => 'n'});
				$cert->delete();
				$nicks->delete();
		}
		if($hist->to_flag eq 'p'){
			my @elem_roles =  $c->model('OntoExtract::Role')->search( { id_person => $hist->id_to });
			foreach my $rolex (@elem_roles)
			{
				 $rolex->update({
				id_person => undef
			});
			}
		}
		if($hist->to_flag eq 'o'){
			my @elem_roles =  $c->model('OntoExtract::Role')->search( { id_organization => $hist->id_to });
			foreach my $rolex (@elem_roles)
			{
				 $rolex->update({
				id_organization => undef
			});
			}
		}
		
		$hist->delete(); 
	}

foreach my $resrel (@relatedurl)
	{
		my $cert = $c->model('OntoExtract::Certainty')->find({id_to => $resrel->id_relatedurl, to_flag => 'u'});
		 $cert->delete();
		 $resrel->delete();
	}
foreach my $nicks (@nicknames)
	{
		my $cert = $c->model('OntoExtract::Certainty')->find({id_to => $nicks->id_nickname, to_flag => 'n'});
		 $cert->delete();
		 $nicks->delete();
	}
	$certainty->delete();
	$role->delete();
my @res = $c->model('OntoExtract::Role')->all;
$c->stash(role_res_nr => \@res);
	
## Send the role back to the changed profile
if($params->{type} eq 'p')
{
	return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $idred ]) );
}
if($params->{type} eq 'o')
{
	return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $idred ]) );
}
}

return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('results'),[0]),$c->stash->{'message'} = "You don't have permission to delete" );
}

}

sub editbyid : Chained('base') :PathPart('editbyid'): Args(0) {
my ($self, $c) = @_;

if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	

if(lc $c->req->method eq 'post') {
my $params = $c->req->params;
my $role =  $c->model('OntoExtract::Role')->search( { id_role => $params->{id_role} });
my $idred = $params->{idredir};
if($params->{type} eq 'p'){
	 if($params->{id} eq '') {
		$role->update({
		id_person => undef
	});
	}else {	 
	 $role->update({
			id_person => $params->{id}
		});
	}
}
if($params->{type} eq 'o'){
	 if($params->{id} eq '') {
		$role->update({
		id_organization => undef
	});
	}else {
	 $role->update({
			id_organization => $params->{id}
		});
	}
}

		
	

	
		
## Send the role back to the changed profile
if($params->{type} eq 'p')
{
	return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $idred ]) );
}
if($params->{type} eq 'o')
{
	return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $idred ]) );
}


}
}

sub get_tree_leafs {
	my($self, $c, @nodes) = @_;
	my @result = ();
	foreach my $node (@nodes){
			my @res =  $c->model('OntoExtract::Certainty')->search( { id_from => $node->id_to, from_flag => $node->to_flag });
			@result = (@result, @res);
		}
	if(scalar(@result) == 0) {
		return ();
	} else {
		
		@result = (@result, get_tree_leafs($self, $c, @result));
	}
	return @result;
}

sub get_name {
	my ($self, $c, $id, $type) = @_;	
	my $rs = get_element($self, $c, $id, $type);
	return $rs->name;
}

sub get_element {
	my ($self, $c, $id, $type) = @_;
	my $table;
	$table = 'OntoExtract::Person' if($type eq 'p'); 
	$table = 'OntoExtract::Organization' if($type eq 'o');
	$table = 'OntoExtract::Role' if($type eq 'r');
	$table = 'OntoExtract::Nickname' if($type eq 'n');
	$table = 'OntoExtract::Relatedurl' if($type eq 'u');	

	return $c->model($table)->find($id);
}

=head1 AUTHOR

Paixao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
