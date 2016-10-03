package OntoExtract::Controller::News;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

OntoExtract::Controller::News - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched OntoExtract::Controller::News in News.');
}


=head1 AUTHOR

Paixao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
