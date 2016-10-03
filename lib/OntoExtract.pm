package OntoExtract;
use Moose;
use namespace::autoclean;
use lib "/home/paixao/OntoExtract";
use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Unicode::Encoding
    Static::Simple

	
	Authentication
	Session
	Session::State::Cookie
	Session::Store::FastMmap

/;

extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

# Configure the application.
#
# Note that settings in ontoextract.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'OntoExtract',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
'View::Web' => {
INCLUDE_PATH => [
__PACKAGE__->path_to('root', 'src'),
__PACKAGE__->path_to('root', 'lib')
],
TEMPLATE_EXTENSION => '.tt',
CATALYST_VAR => 'c',
TIMER => 0,
WRAPPER => 'site/wrapper'
},
'Plugin::Authentication' => {
default => {
credential => {
class => 'Password',
password_type => 'crypted'
},
store => {
class => 'DBIx::Class',
user_model => 'OntoExtract::User',
use_userdata_from_session => '1'
}
}
} );


# Start the application
__PACKAGE__->setup();


=head1 NAME

OntoExtract - Catalyst based application

=head1 SYNOPSIS

    script/ontoextract_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<OntoExtract::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Paixao,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
