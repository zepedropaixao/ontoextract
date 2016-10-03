package OntoExtract::Controller::Clearance;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

OntoExtract::Controller::Clearance - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched OntoExtract::Controller::Clearance in Clearance.');
}

sub login :Local :Args(0) {
my ( $self, $c ) = @_;
$c->stash->{'template'} = 'site/home.tt';
if ( exists($c->req->params->{'username'}) ) {
if ($c->authenticate( {
username => $c->req->params->{'username'},
password => $c->req->params->{'password'}
}) )
{
## user is signed in
my $laccess = $c->user->lastaccess;
my $laccessd = $laccess->dmy('-');
my $laccessh = $laccess->hms(':');
my $dtnow = DateTime->now();
$c->user->update({
		lastaccess => $dtnow
		});


$c->response->redirect($c->uri_for($c->controller('Root')->action_for('index') ),$c->stash->{'message'} = "Your last login was on day $laccessd at $laccessh");
$c->detach();
return;
}
else {
$c->stash->{'message'} = "Invalid login.";
}
}
}

sub logout :Local :Args(0) {
my ( $self, $c ) = @_;
$c->stash->{'template'} = 'site/home.tt';
$c->logout();
$c->stash->{'message'} = "You have been logged out.";
}



=head1 AUTHOR

Paixao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
