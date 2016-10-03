package OntoExtract::Controller::Person;
use Moose;
use namespace::autoclean;
use Time::Local;
use GraphViz;
use utf8;
use POSIX;
BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

OntoExtract::Controller::Person - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base : Chained('/'): PathPart('person'): CaptureArgs(0) {
my ($self, $c) = @_;
my $rs = $c->model('OntoExtract::Person')->search( {}, { page => 1, rows => 10, order_by => 'name' });
my $per_pager = $rs->pager;
my $total_per = $per_pager->total_entries;
$c->stash(total_per_rs => $total_per);
$c->stash(per_res_nr => $rs->page(1));
$c->stash(person_rs => $c->model('OntoExtract::Person'));
$c->stash(certainty_rs => $c->model('OntoExtract::Certainty'));
}

sub search : Chained('base'): PathPart('search'): Args(0) {
	my ($self, $c) = @_;
	if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
	$c->stash->{'template'} = 'person/list.tt';
	if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;
	my $searchq = $params->{searchquery};
	my @per_search_rs =  $c->model('OntoExtract::Person')->search( { name => { like => '%'.$searchq.'%' } }, { order_by => 'name'});
	
	return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('results'),[ 0 ]),$c->stash(per_res_nr => \@per_search_rs) );
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
	## Retrieve the person_rs stashed by the base action:
	my $person_rs = $c->stash->{person_rs};
	my $certainty_rs = $c->stash->{certainty_rs};
   

	## Create the person:
	my $newper = eval { $person_rs->create({
		name => $params->{name},
	sex => $params->{sex},
	title => $params->{title},
	picture => $params->{picture},
	country => $params->{country},
	address => $params->{address},
	criminalrecord => $params->{criminalrecord},
	abstract => $params->{abstract},
	articlelink => $params->{articlelink},
	tagharem => $params->{tagharem},
	notes => $params->{notes},
	incompleteflag => $params->{incompleteflag}
	}) };
	
	foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $newper->update({
			$key => "v"
		});
	 
	 } 
	}

	 if($params->{birthday} ne '' && $params->{birthday} ne "0000-00-00" ) {
		$newper->update({
		birthday => $params->{birthday}
	});
	}
	if($params->{deathday} ne '' && $params->{deathday} ne "0000-00-00" ) {
		$newper->update({
		deathday => $params->{deathday}
	});
	}
	my $newcertainty = eval { $certainty_rs->create({
	id_to => $newper->id_person,
	to_flag => 'p',
	method_certainty => 0,
	final_certainty => 10,
	nr_hits => 0
	}) };
	## Send the person to view the newly created person
	return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $newper->id ]) );
}
}

sub list : Chained('base') :PathPart(''): CaptureArgs(1) {
my($self, $c, $perpagein) = @_;

$c->stash->{'perpage'} = $perpagein;

}

sub results : Chained('list') :PathPart('list'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
  $c->stash->{template} = "person/list.tt";
}

sub person : Chained('base'): PathPart(''): CaptureArgs(1) {
my ($self, $c, $personid) = @_;

if($personid =~ /\D/) {
die "Misuse of URL, userid does not contain only digits!";
}

my $person = $c->stash->{person_rs}->find({ id_person => $personid },
				{ key => 'primary' });
	die "No such person" if(!$person);
	$c->stash(person => $person);
	
}

sub history : Chained('person') :PathPart('history'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}
my $person = $c->stash->{person};
my $id = $person->id_person;
	
my $elem = $c->model('OntoExtract::Certainty')->find( {id_to => $id, to_flag => 'p'});


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
		if($back->id_to == $id && $back->to_flag eq 'p'){
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
	if($back->id_to == $id && $back->to_flag eq 'p'){
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

open (PNG, ">../root/static/images/trees/".$id."_p.png");
print PNG $g->as_png;
close PNG;	
	
	
}

sub profile : Chained('person') :PathPart('profile'): Args(0) {
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

my $person = $c->stash->{person};
my $relpage;
my $refpage;
my $rolepage;
my $nickpage;
my $show_all_org = 0;
my $show_edit = 0;
if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;
	$relpage = $params->{relpage};
	$refpage = $params->{refpage};
	$rolepage = $params->{rolepage};
	$nickpage = $params->{nickpage};
	$show_all_org = $params->{show_all_org};
	$show_edit = $params->{show_edit};
}
$relpage = 1 if(!$relpage);
$refpage = 1 if(!$refpage);
$rolepage = 1 if(!$rolepage);
$nickpage = 1 if(!$nickpage);
$show_all_org = 0 if(!$show_all_org);
$show_edit = 0 if(!$show_edit);
$c->stash(show_edit => $show_edit);

my $res_role = $c->model('OntoExtract::Role')->search( {id_person => $person->id_person}, { page => 1, rows => 5, order_by => 'name' });
my $empty_role = $c->model('OntoExtract::Role')->search( {id_person => undef }, {  order_by => 'name' });
my @role_array = $res_role->all;
my $role_pager = $res_role->pager;
my $total_role = $role_pager->total_entries;
$c->stash(rolepage => $rolepage);
$c->stash(total_role_rs => $total_role);
$c->stash(role_res_nr => $res_role);
$c->stash(empty_roles => $empty_role);

my $match = "";
foreach my $role (@role_array) {
		if(defined($role->id_organization)){
			if(length($match)>0){				
				$match = $match . "|" . $role->id_organization;
			}else {
				$match = "^(" . $role->id_organization;
			}
		}
	}
if (length($match) > 0) {
	$match = $match . ")\$";
	my $resorg1 = $c->model('OntoExtract::Organization')->search( {id_organization => { regexp => $match }}, {order_by => 'name' });
	$c->stash(org_res_nr => $resorg1);
}
if($show_all_org == 1){
	my $resorg2 = $c->model('OntoExtract::Organization')->search( {}, {order_by => 'name' });
	$c->stash(org_res_nr => $resorg2);
}


my $relres = $c->model('OntoExtract::Relatedurl')->search( {fromwho_id => $person->id_person, fromwho_flag => 'p', type_flag => 'r'}, { page => 1, rows => 5 });
my $rel_pager = $relres->pager;
my $total_rel = $rel_pager->total_entries;
$c->stash(relpage => $relpage);
$c->stash(total_rel_rs => $total_rel);
$c->stash(rel_res_nr => $relres);


my $refres = $c->model('OntoExtract::Relatedurl')->search( {fromwho_id => $person->id_person, fromwho_flag => 'p', type_flag => 'b'}, { page => 1, rows => 5 });
my $ref_pager = $refres->pager;
my $total_ref = $ref_pager->total_entries;
$c->stash(refpage => $refpage);
$c->stash(total_ref_rs => $total_ref);
$c->stash(ref_res_nr => $refres);

my $nickres = $c->model('OntoExtract::NickName')->search( {fromwho_id => $person->id_person, fromwho_flag => 'p'}, { page => 1, rows => 5, order_by => 'name' });
my $nick_pager = $nickres->pager;
my $total_nick = $nick_pager->total_entries;
$c->stash(nickpage => $nickpage);
$c->stash(total_nick_rs => $total_nick);
$c->stash(nick_res_nr => $nickres);


	
}

sub del : Chained('person') :PathPart('del'): Args(0) {
my ( $self, $c ) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to delete any person." ;
	return;
}	
my $person = $c->stash->{person};
my $name = $c->stash->{person}->name;
$c->stash->{template} = "person/list.tt";
my $iddel = $c->stash->{person}->id_person;
 
  
 my @relatedurl =  $c->model('OntoExtract::RelatedURL')->search( { fromwho_id => $iddel, fromwho_flag => 'p' });
 my @nicknames =  $c->model('OntoExtract::NickName')->search( { fromwho_id => $iddel, fromwho_flag => 'p' });
  my @roles =  $c->model('OntoExtract::Role')->search( { id_person => $iddel });
  my $certainty = $c->model('OntoExtract::Certainty')->find({id_to => $iddel, to_flag => 'p'});

my @history =  get_tree_leafs($self, $c, ($certainty));

 if($c->user_exists() && ($c->user->role eq 'admin' || $c->user->role eq 'operator')) {
	 
	foreach my $rolex (@roles)
	{
		 $rolex->update({
		id_person => undef
	});
	}

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
	
	$person->delete();

my @res = $c->model('OntoExtract::Person')->all;
$c->stash(per_res_nr => \@res);

return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('results'),[0]),$c->stash->{'message'} = "You have eliminated person $name" );
}

return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('results'),[0]),$c->stash->{'message'} = "You don't have permission to delete $name" );
}

sub edit : Chained('person') :PathPart('edit'): Args(0) {
my ($self, $c) = @_;

if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	

if(lc $c->req->method eq 'post') {
my $params = $c->req->params;
my $person = $c->stash->{person};
my $id_per = $c->stash->{person}->id_person;

## TODO Check security to update person

## Update person
$person->update({
	name => $params->{name},
	sex => $params->{sex},
	title => $params->{title},
	picture => $params->{picture},
	country => $params->{country},
	address => $params->{address},
	criminalrecord => $params->{criminalrecord},
	abstract => $params->{abstract},
	articlelink => $params->{articlelink},
	tagharem => $params->{tagharem},
	notes => $params->{notes},
	incompleteflag => $params->{incompleteflag},
	name_valid => "",
	sex_valid => "",
	title_valid => "",
	picture_valid => "",
	country_valid => "",
	address_valid => "",
	criminalrecord_valid => "",
	abstract_valid => "",
	articlelink_valid => "",
	tagharem_valid => "",
	birthday_valid => "",
	deathday_valid => ""
		});
		
		foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 
		 
		 $person->update({
			$key => "v"
		});
		if($key eq "name_valid"){
			my $certainty = $c->model('OntoExtract::Certainty')->find( {id_to => $id_per, to_flag => 'p'});
			$certainty->update({
				final_certainty => "100"				
				});
			my $now = strftime("%Y/%m/%d - %R", localtime(time));
			my $out_file = ">>../script/logs/validation/". $c->user->name ."_".$c->user->role.".txt";
			open (EDITLOG, $out_file);
			print (EDITLOG "[$now] - validation of Person: ".$person->name ."\n");
			close (EDITLOG);
		}
		
		
	 
	 } 
	}
		 if($params->{birthday} ne '' && $params->{birthday} ne "0000-00-00" ) {
		$person->update({
		birthday => $params->{birthday}
	});
	}
	if($params->{deathday} ne '' && $params->{deathday} ne "0000-00-00" ) {
		$person->update({
		deathday => $params->{deathday}
	});
	}
		
## Send the person back to the changed profile
return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $person->id_person ]) );
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
	my $rs = $c->model($table)->find($id);
	return $rs;
}

=head1 AUTHOR

Paixao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
