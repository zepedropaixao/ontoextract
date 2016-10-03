package OntoExtract::Controller::RelatedURL;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

OntoExtract::Controller::RelatedURL - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base : Chained('/'): PathPart('relatedurl'): CaptureArgs(0) {
my ($self, $c) = @_;
my @relres = $c->model('OntoExtract::Relatedurl')->all;
$c->stash(rel_res_nr => \@relres);
$c->stash(relatedurl_rs => $c->model('OntoExtract::Relatedurl'));
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
	## Retrieve the relatedurl_rs stashed by the base action:
	my $relatedurl_rs = $c->stash->{relatedurl_rs};
	my $certainty_rs = $c->stash->{certainty_rs};
   

	## Create the RelatedURL:
	my $newrel = eval { $relatedurl_rs->create({
	name => $params->{name},
	type_flag => $params->{type_flag},
	fromwho_flag => $params->{fromwho_flag},
	fromwho_id => $params->{fromwho_id}
	}) };
	
	foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $newrel->update({
			$key => "v"
		});
	 
	 } 
	}
	my $newcertainty = eval { $certainty_rs->create({
	id_to => $newrel->id_relatedurl,
	to_flag => 'u',
	method_certainty => 0,
	final_certainty => 100,
	nr_hits => 0
	}) };
	## Send the person back to the changed profile
	if($params->{fromwho_flag} eq 'p'){
return $c->res->redirect( $c->uri_for($c->controller('Person')->action_for('profile'),[ $newrel->fromwho_id ]) );
	
	}
	if($params->{fromwho_flag} eq 'o'){
		return $c->res->redirect( $c->uri_for($c->controller('Organization')->action_for('profile'),[ $newrel->fromwho_id ]) );
	}
	if($params->{fromwho_flag} eq 'r'){
		return $c->res->redirect( $c->uri_for($c->controller('Role')->action_for('profile'),[ $newrel->fromwho_id ]) );
	}
	
}
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
my $relatedurl =  $c->model('OntoExtract::RelatedURL')->find($params->{id_relatedurl});
my $certainty = $c->model('OntoExtract::Certainty')->find({id_to => $params->{id_relatedurl}, to_flag => 'u'});
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
$relatedurl->delete();
my @relres = $c->model('OntoExtract::Relatedurl')->all;
$c->stash(rel_res_nr => \@relres);
$c->stash(relatedurl_rs => $c->model('OntoExtract::Relatedurl'));

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
my $relatedurl =  $c->model('OntoExtract::RelatedURL')->search( { id_relatedurl => $params->{id_relatedurl} });
 $c->stash->{template} = "person/profile.tt";
 my $redid = $params->{fromwho_id};


## Update person
$relatedurl->update({
	fromwho_flag => $params->{fromwho_flag},
	fromwho_id => $params->{fromwho_id},
	name => $params->{name},
	type_flag => $params->{type_flag},
	name_valid => ""
		});
		
		
		foreach my $key (keys %{$params})
	{
	 if($key=~/_valid$/ ){
		 $relatedurl->update({
			$key => "v"
		});
	 
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
