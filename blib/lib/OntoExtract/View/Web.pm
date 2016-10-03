package OntoExtract::View::Web;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
	ENCODING     => 'utf-8',
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

OntoExtract::View::Web - TT View for OntoExtract

=head1 DESCRIPTION

TT View for OntoExtract.

=head1 SEE ALSO

L<OntoExtract>

=head1 AUTHOR

Paixao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
