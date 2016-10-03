package OntoExtract::Controller::User;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

OntoExtract::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/'): PathPart('user'): CaptureArgs(0) {
my ($self, $c) = @_;
my @res_user = $c->model('OntoExtract::User')->all;
$c->stash(user_res_nr => \@res_user);
$c->stash(user_rs => $c->model('OntoExtract::User'));
}

sub search : Chained('base'): PathPart('search'): Args(0) {
	my ($self, $c) = @_;
	if(!$c->user_exists()) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
	$c->stash->{'template'} = 'user/list.tt';
	if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;
	my $searchq = $params->{searchquery};
	my @usr_search_rs =  $c->model('OntoExtract::User')->search( { name => { like => '%'.$searchq.'%' } }, { order_by => 'name'});
	
	return $c->res->redirect( $c->uri_for($c->controller('User')->action_for('results'),[ 0 ]),$c->stash(user_res_nr => \@usr_search_rs) );
}
}

sub add : Chained('base'): PathPart('add'): Args(0) {
my ($self, $c) = @_;

if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}
if(lc $c->req->method eq 'post') {
	my $params = $c->req->params;

	## Retrieve the user_rs stashed by the base action:
	my $user_rs = $c->stash->{user_rs};


	## Encrypt user password
	my $pwd = crypt($params->{password}, join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64]);
	

	## Create the user:
	my $newuser = eval { $user_rs->create({
		username => $params->{username},
		password => $pwd,
		role => $params->{role},
		name => $params->{name},
		email => $params->{email},
		notes => $params->{notes},
		status => 'active'
	}) };
	if($@) {
	$c->log->debug($@ ,
	"User tried to sign up with an invalid email address, redoing.. ");
	$c->stash( errors => { email => 'invalid' }, err => $@ );
	return;
	}
	## Send the user to view the newly created user
	return $c->res->redirect( $c->uri_for(
	$c->controller('User')->action_for('profile'),
	[ $newuser->id ]
	) );
	
}


}

sub list : Chained('base') :PathPart(''): CaptureArgs(1) {
my($self, $c, $userpagein) = @_;

$c->stash->{'userpage'} = $userpagein;

}

sub results : Chained('list') :PathPart('list'): Args(0) {
my ($self, $c) = @_;
if(!$c->user_exists()|| ($c->user_exists() && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}	
  $c->stash->{template} = "user/list.tt";
}

sub user : Chained('base'): PathPart(''): CaptureArgs(1) {
my ($self, $c, $userid) = @_;
if(!$c->user_exists() || ($c->user_exists() && $c->user->id_user != $userid && $c->user->role ne 'admin' && $c->user->role ne 'operator')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}
if($userid =~ /\D/) {
die "Misuse of URL, userid does not contain only digits!";
}

my $user = $c->stash->{user_rs}->find({ id_user => $userid },
				{ key => 'primary' });
	die "No such user" if(!$user);
	$c->stash(user => $user);
	

}

sub profile : Chained('user') :PathPart('profile'): Args(0) {
my ($self, $c) = @_;
	
}

sub del : Chained('user') :PathPart('del'): Args(0) {
my ( $self, $c ) = @_;
if(!$c->user_exists() || ($c->user_exists() && $c->user->role ne 'admin')) {
	$c->stash->{'template'} = 'site/home.tt';
	$c->stash->{'message'} = "You don't have permission to view this page" ;
	return;
}
my $user = $c->stash->{user};
my $name = $c->stash->{user}->name;

$c->stash->{template} = "user/list.tt";

 if($c->user_exists() && $c->user->role eq 'admin') {
$user->delete();
my @res_user = $c->model('OntoExtract::User')->all;
$c->stash(user_res_nr => \@res_user);

return $c->res->redirect( $c->uri_for($c->controller('User')->action_for('results'),[0]),$c->stash->{'message'} = "You have eliminated user $name" );
}

return $c->res->redirect( $c->uri_for($c->controller('User')->action_for('results'),[0]),$c->stash->{'message'} = "You don't have permission to delete $name" );

}

sub edit : Chained('user') :PathPart('edit'): Args(0) {
my ($self, $c) = @_;
my $user = $c->stash->{user};

if(lc $c->req->method eq 'post') {
my $params = $c->req->params;


my $pwd = "";
## Encrypt user password
if($params->{password} ne "") {
	$pwd = crypt($params->{password}, join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64]);
}
if($pwd eq ""){
	$pwd = $user->password;	
	}
## Update user's email and/or password
$user->update({
	
		password => $pwd,
	
		role => $params->{role},
		name => $params->{name},
		email => $params->{email},
		notes => $params->{notes},
		status => $params->{status}
		});
## Send the user back to the changed profile
return $c->res->redirect( $c->uri_for($c->controller('User')->action_for('profile'),[ $user->id_user ]) );
}
}





=head1 AUTHOR

Paixao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
