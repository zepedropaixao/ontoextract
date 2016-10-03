package OntoExtract::Controller::Organization;
use Moose;
use namespace::autoclean;
use Time::Local;
use utf8;
use POSIX;
BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

OntoExtract::Controller::Organization - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base : Chained('/'): PathPart('organization'): CaptureArgs(0) {
my ($self, $c) = @_;
my $rs = $c->model('OntoExtract::Organization')->search( {}, { page => 1, rows => 10, order_by => 'name' });
my $org_pager = $rs->pager;
my $total_org = $org_pager->total_entries;
$c->stash(total_org_rs => $total_org);
$c->stash(org_res_nr => $rs->page(1));
$c->stash(organization_rs => $c->model('OntoExtract::Organization'));
$c->stash(certainty_rs => $c->model('OntoExtract::Certainty'));


}

sub search : Chained('base'): PathPart('search'): Args(0) {
	my ($self, $c) = @_;
	if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
	$c->stash->{'template'} = 'organization/list.tt';
	if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;
	my $searchq = $params->{searchquery};
	my @search_rs =  $c->model('OntoExtract::Organization')->search( { name => { like => '%'.$searchq.'%' } }, { order_by => 'name'});
	
	return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('results'),[ 0 ]),$c->stash(org_res_nr => \@search_rs) );
}
}

sub add : Chained('base'): PathPart('add'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;

	## Retrieve the organization_rs stashed by the base action:
	my $organization_rs = $c->stash->{organization_rs};
	my $certainty_rs = $c->stash->{certainty_rs};
   

	## Create the organization:
	my $neworg = eval { $organization_rs->create({
	name => $params->{name},
	slogan => $params->{slogan},
	logo => $params->{logo},
	country => $params->{country},
	hqaddress => $params->{hqaddress},
	abstract => $params->{abstract},
	articlelink => $params->{articlelink},
	tagharem => $params->{tagharem},
	notes => $params->{notes},
	incompleteflag => $params->{incompleteflag}
	}) };
	foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $neworg->update({
			$key => "v"
		});
	 
	 } 
	}
	 if($params->{foundationday} ne '' && $params->{foundationday} ne "0000-00-00" ) {
		$neworg->update({
		foundationday => $params->{foundationday}
	});
	}
	if($params->{endday} ne '' && $params->{endday} ne "0000-00-00" ) {
		$neworg->update({
		endday => $params->{endday}
	});
	}
	my $newcertainty = eval { $certainty_rs->create({
	id_to => $neworg->id_organization,
	to_flag => 'o',
	method_certainty => 0,
	final_certainty => 100,
	nr_hits => 0
	}) };
	## Send the organization to view the newly created organization
	return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $neworg->id ]) );
}
}

sub list : Chained('base') :PathPart(''): CaptureArgs(1) {
my($self, $c, $orgpagein) = @_;

$c->stash->{'orgpage'} = $orgpagein;

}

sub results : Chained('list') :PathPart('list'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
  $c->stash->{template} = "organization/list.tt";
}

sub organization : Chained('base'): PathPart(''): CaptureArgs(1) {
my ($self, $c, $organizationid) = @_;
if($organizationid =~ /\D/) {
die "Misuse of URL, userid does not contain only digits!";
}

my $organization = $c->stash->{organization_rs}->find({ id_organization => $organizationid },
				{ key => 'primary' });
	die "No such organization" if(!$organization);
	$c->stash(organization => $organization);
}

sub history : Chained('organization') :PathPart('history'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}
my $organization = $c->stash->{organization};
my $id = $organization->id_organization;
	
my $elem = $c->model('OntoExtract::Certainty')->find( {id_to => $id, to_flag => 'o'});


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
		if($back->id_to == $id && $back->to_flag eq 'o'){
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
	if($back->id_to == $id && $back->to_flag eq 'o'){
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

open (PNG, ">../root/static/images/trees/".$id."_o.png");
print PNG $g->as_png;
close PNG;	
	
	
}

sub profile : Chained('organization') :PathPart('profile'): Args(0) {
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

$c->stash(get_element => sub { my ($id,$type) = @_;
my $table;
	$table = 'OntoExtract::Person' if($type eq 'p'); 
	$table = 'OntoExtract::Organization' if($type eq 'o');
	$table = 'OntoExtract::Role' if($type eq 'r');
	$table = 'OntoExtract::Nickname' if($type eq 'n');
	$table = 'OntoExtract::Relatedurl' if($type eq 'u');	
	
	my $rs = $c->model($table)->find($id);
	return $rs;
});


my $organization = $c->stash->{organization};
my $relpage;
my $refpage;
my $rolepage;
my $nickpage;
my $show_all_per = 0;
my $show_edit = 0;
if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;
	$relpage = $params->{relpage};
	$refpage = $params->{refpage};
	$rolepage = $params->{rolepage};
	$nickpage = $params->{nickpage};
	$show_all_per = $params->{show_all_per};
	$show_edit = $params->{show_edit};
}
$relpage = 1 if(!$relpage);
$refpage = 1 if(!$refpage);
$rolepage = 1 if(!$rolepage);
$nickpage = 1 if(!$nickpage);
$show_all_per = 0 if(!$show_all_per);
$show_edit = 0 if(!$show_edit);
$c->stash(show_edit => $show_edit);

my $relres = $c->model('OntoExtract::Relatedurl')->search( {fromwho_id => $organization->id_organization, fromwho_flag => 'o', type_flag => 'r'}, { page => 1, rows => 5 });
my $rel_pager = $relres->pager;
my $total_rel = $rel_pager->total_entries;
$c->stash(relpage => $relpage);
$c->stash(total_rel_rs => $total_rel);
$c->stash(rel_res_nr => $relres);


my $refres = $c->model('OntoExtract::Relatedurl')->search( {fromwho_id => $organization->id_organization, fromwho_flag => 'o', type_flag => 'b'}, { page => 1, rows => 5 });
my $ref_pager = $refres->pager;
my $total_ref = $ref_pager->total_entries;
$c->stash(refpage => $refpage);
$c->stash(total_ref_rs => $total_ref);
$c->stash(ref_res_nr => $refres);

my $nickres = $c->model('OntoExtract::NickName')->search( {fromwho_id => $organization->id_organization, fromwho_flag => 'o'}, { page => 1, rows => 5, order_by => 'name' });
my $nick_pager = $nickres->pager;
my $total_nick = $nick_pager->total_entries;
$c->stash(nickpage => $nickpage);
$c->stash(total_nick_rs => $total_nick);
$c->stash(nick_res_nr => $nickres);

my $res_role = $c->model('OntoExtract::Role')->search( {id_organization => $organization->id_organization}, { page => 1, rows => 5, order_by => 'name' });
my $empty_role = $c->model('OntoExtract::Role')->search( {id_organization => undef }, { order_by => 'name' });
my @role_array = $res_role->all;
my $role_pager = $res_role->pager;
my $total_role = $role_pager->total_entries;
$c->stash(rolepage => $rolepage);
$c->stash(total_role_rs => $total_role);
$c->stash(role_res_nr => $res_role);
$c->stash(empty_roles => $empty_role);

my $match = "";
foreach my $role (@role_array) {
		if(defined($role->id_person)){
			if(length($match)>0){				
				$match = $match . "|" . $role->id_person;
			}else {
				$match = "^(" . $role->id_person;
			}
		}
	}
if (defined($match)) { 
	$match = $match . ")\$";
	my $resper = $c->model('OntoExtract::Person')->search( {id_person => { regexp => $match }}, { order_by => 'name' });
	$c->stash(per_res_nr => $resper);
}
if($show_all_per == 1){
	my $resper = $c->model('OntoExtract::Person')->search( {}, { order_by => 'name' });
	$c->stash(per_res_nr => $resper);
}







}

sub del : Chained('organization') :PathPart('del'): Args(0) {
my ( $self, $c ) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to delete any organization." ;
	return;
}	
my $organization = $c->stash->{organization};
my $name = $c->stash->{organization}->name;
my $iddel = $c->stash->{organization}->id_organization;
 $c->stash->{template} = "organization/list.tt";
 
  my @relatedurl =  $c->model('OntoExtract::RelatedURL')->search( { fromwho_id => $iddel, fromwho_flag => 'o' });
 my @nicknames =  $c->model('OntoExtract::NickName')->search( { fromwho_id => $iddel, fromwho_flag => 'o' });
  my @roles =  $c->model('OntoExtract::Role')->search( { id_organization => $iddel });
  my $certainty = $c->model('OntoExtract::Certainty')->find({id_to => $iddel, to_flag => 'o'});
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


	foreach my $rolex (@roles)
	{
		 $rolex->update({
		id_organization => undef
	});
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
$organization->delete();

my @res = $c->model('OntoExtract::Organization')->all;
$c->stash(org_res_nr => \@res);

return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('results'),[0]),$c->stash->{'message'} = "You have eliminated organization $name" );
}

return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('results'),[0]),$c->stash->{'message'} = "You don't have permission to delete $name" );


}

sub edit : Chained('organization') :PathPart('edit'): Args(0) {
my ($self, $c) = @_;

if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	

if(lc $c->req->method eq 'post') {
my $params = $c->req->params;
my $organization = $c->stash->{organization};
my $id_org = $c->stash->{organization}->id_organization;

## Update organization
$organization->update({
	name => $params->{name},
	slogan => $params->{slogan},
	logo => $params->{logo},
	country => $params->{country},
	hqaddress => $params->{hqaddress},
	abstract => $params->{abstract},
	articlelink => $params->{articlelink},
	tagharem => $params->{tagharem},
	notes => $params->{notes},
	incompleteflag => $params->{incompleteflag},
	name_valid => "",
	slogan_valid => "",
	logo_valid => "",
	country_valid => "",
	hqaddress_valid => "",
	abstract_valid => "",
	articlelink_valid => "",
	tagharem_valid => "",
	foundationday_valid => "",
	endday_valid => ""
		});
		
			foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $organization->update({
			$key => "v"
		});
		if($key eq "name_valid"){
			my $certainty = $c->model('OntoExtract::Certainty')->find( {id_to => $id_org, to_flag => 'o'});
			$certainty->update({
				final_certainty => "100"				
				});
			my $now = strftime("%Y/%m/%d - %R", localtime(time));
			my $out_file = ">>../script/logs/validation/". $c->user->name ."_".$c->user->role.".txt";
			open (EDITLOG, $out_file);
			print (EDITLOG "[$now] - validation of Organization: ".$organization->name ."\n");
			close (EDITLOG);
		}
		
	 
	 } 
	}
		 if($params->{foundationday} ne '' && $params->{foundationday} ne "0000-00-00" ) {
		$organization->update({
		foundationday => $params->{foundationday}
	});
	}
	if($params->{endday} ne '' && $params->{endday} ne "0000-00-00" ) {
		$organization->update({
		endday => $params->{endday}
	});
	}
		
## Send the organization back to the changed profile
return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $organization->id_organization ]) );
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
