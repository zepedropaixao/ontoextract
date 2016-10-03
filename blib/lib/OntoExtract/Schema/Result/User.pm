package OntoExtract::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 NAME

OntoExtract::Schema::Result::User

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id_user

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 role

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 email

  data_type: 'text'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  default_value: 'active'
  is_nullable: 0
  size: 16

=head2 lastaccess

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_user",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "role",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "email",
  { data_type => "text", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
  "status",
  {
    data_type => "varchar",
    default_value => "active",
    is_nullable => 0,
    size => 16,
  },
  "lastaccess",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);
__PACKAGE__->set_primary_key("id_user");
__PACKAGE__->add_unique_constraint("UQ_user_username", ["username"]);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-02 12:42:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ij1Ny8as7zk0H38oweYrww


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->add_columns('lastaccess',
{ %{__PACKAGE__->column_info('lastaccess') },
set_on_create => 1,
set_on_update => 1
});

use Email::Valid;
sub new {
my ($class, $args) = @_;
if( exists $args->{email} && !Email::Valid->address($args->{email}) ) { die 'Email invalid'; }
return $class->next::method($args);
}

1;
