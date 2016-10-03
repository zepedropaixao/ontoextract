package OntoExtract::Controller::NickName;
use Moose;
use namespace::autoclean;
use utf8;
use POSIX;
BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

OntoExtract::Controller::NickName - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut
sub base : Chained('/'): PathPart('nickname'): CaptureArgs(0) {
my ($self, $c) = @_;
my @nickres = $c->model('OntoExtract::NickName')->all;
$c->stash(nick_res_nr => \@nickres);
$c->stash(nickname_rs => $c->model('OntoExtract::NickName'));
$c->stash(certainty_rs => $c->model('OntoExtract::Certainty'));
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
	## Retrieve the nickname_rs stashed by the base action:
	my $nickname_rs = $c->stash->{nickname_rs};
	my $certainty_rs = $c->stash->{certainty_rs};

	## Create the NickName:
	my $newnick = eval { $nickname_rs->create({
	name => $params->{name},
	fromwho_flag => $params->{fromwho_flag},
	fromwho_id => $params->{fromwho_id}
	}) };
	
	foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $newnick->update({
			$key => "v"
		});
	 
	 } 
	}
	
	my $newcertainty = eval { $certainty_rs->create({
	id_to => $newnick->id_nickname,
	to_flag => 'n',
	method_certainty => 0,
	final_certainty => 100,
	nr_hits => 0
	}) };
	
	## Send the person back to the changed profile
	if($params->{fromwho_flag} eq 'p'){
return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $newnick->fromwho_id ]) );
	
	}
	if($params->{fromwho_flag} eq 'o'){
		return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $newnick->fromwho_id ]) );
	}
	if($params->{fromwho_flag} eq 'r'){
return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('profile'),[ $newnick->fromwho_id ]) );
	
	}
	
}
}

sub nickname : Chained('base'): PathPart(''): CaptureArgs(1) {
my ($self, $c, $nickid) = @_;

if($nickid =~ /\D/) {
die "Misuse of URL, userid does not contain only digits!";
}

my $nick = $c->stash->{nickname_rs}->find({ id_nickname => $nickid },
				{ key => 'primary' });
	die "No such person" if(!$nick);
	$c->stash(nickname => $nick);
	
}

sub history : Chained('nickname') :PathPart('history'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}
my $nickname = $c->stash->{nickname};
my $id = $nickname->id_nickname;
	
my $elem = $c->model('OntoExtract::Certainty')->find( {id_to => $id, to_flag => 'n'});


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
		if($back->id_to == $id && $back->to_flag eq 'n'){
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
	if($back->id_to == $id && $back->to_flag eq 'n'){
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

open (PNG, ">../root/static/images/trees/".$id."_n.png");
print PNG $g->as_png;
close PNG;	
	
	
}

sub del :Local :Args(0) {
my ( $self, $c ) = @_;
if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to delete any person." ;
	return;
}
if(lc $c->req->method eq 'post') {
	$c->stash->{'template'} = 'person/profile.tt';
		my $params = $c->req->params;
		my $certainty = $c->model('OntoExtract::Certainty')->find({id_to => $params->{id_nickname}, to_flag => 'n'});

my $nickname =  $c->model('OntoExtract::NickName')->find($params->{id_nickname});
 $c->stash->{template} = "person/profile.tt";
 
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

	 
	 
$certainty->delete();
$nickname->delete();
my @nickres = $c->model('OntoExtract::NickName')->all;
$c->stash(nick_res_nr => \@nickres);
$c->stash(nickname_rs => $c->model('OntoExtract::NickName'));

	if($params->{fromwho_flag} eq 'p'){
		
	return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $params->{fromwho_id} ]) );
	
	}
	if($params->{fromwho_flag} eq 'o'){ 
		return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $params->{fromwho_id} ]) );
	}
		if($params->{fromwho_flag} eq 'r'){
		return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('profile'),[ $params->{fromwho_id} ]) );
	}
}
}

return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('results'),[0]),$c->stash->{'message'} = "You don't have permission to delete" );


}

sub edit : Local : Args(0) {
my ($self, $c) = @_;

if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	

if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;
my $nickname =  $c->model('OntoExtract::NickName')->search( { id_nickname => $params->{id_nickname} });
 $c->stash->{template} = "person/profile.tt";
 my $redid = $params->{fromwho_id};


## Update person
$nickname->update({
	fromwho_flag => $params->{fromwho_flag},
	fromwho_id => $params->{fromwho_id},
	name => $params->{name},
	name_valid => ""
		});
		
		
		foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $nickname->update({
			$key => "v"
		});
		if($key eq "name_valid"){
			my $certainty = $c->model('OntoExtract::Certainty')->find( {id_to => $nickname->id_nickname, to_flag => 'n'});
			$certainty->update({
				final_certainty => "100"				
				});
			my $now = strftime("%Y/%m/%d - %R", localtime(time));
			my $out_file = ">>../script/logs/validation/". $c->user->name ."_".$c->user->role.".txt";
			open (EDITLOG, $out_file);
			print (EDITLOG "[$now] - validation of Nickname: ".$nickname->name ."\n");
			close (EDITLOG);
		}
	 
	 } 
	}
		
## Send the person back to the changed profile
if($params->{fromwho_flag} eq 'p'){
		
	return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $params->{fromwho_id} ]) );
	
	}
	if($params->{fromwho_flag} eq 'o'){
		return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $params->{fromwho_id} ]) );
	}
		if($params->{fromwho_flag} eq 'r'){
		return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('profile'),[ $params->{fromwho_id} ]) );
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
