package OntoExtract::Schema::Result::Role;

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

OntoExtract::Schema::Result::Role

=cut

__PACKAGE__->table("role");

=head1 ACCESSORS

=head2 id_role

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 id_person

  data_type: 'bigint'
  is_nullable: 1

=head2 id_organization

  data_type: 'bigint'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 name_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 startdate

  data_type: 'date'
  is_nullable: 1

=head2 startdate_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 enddate

  data_type: 'date'
  is_nullable: 1

=head2 enddate_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 abstract

  data_type: 'text'
  is_nullable: 1

=head2 abstract_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 articlelink

  data_type: 'text'
  is_nullable: 1

=head2 articlelink_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 incompleteflag

  data_type: 'char'
  default_value: 't'
  is_nullable: 0
  size: 1

=head2 lastmodified

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 type

  data_type: 'char'
  default_value: 'r'
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "id_role",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "id_person",
  { data_type => "bigint", is_nullable => 1 },
  "id_organization",
  { data_type => "bigint", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "name_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "startdate",
  { data_type => "date", is_nullable => 1 },
  "startdate_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "enddate",
  { data_type => "date", is_nullable => 1 },
  "enddate_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "abstract",
  { data_type => "text", is_nullable => 1 },
  "abstract_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "articlelink",
  { data_type => "text", is_nullable => 1 },
  "articlelink_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "incompleteflag",
  { data_type => "char", default_value => "t", is_nullable => 0, size => 1 },
  "lastmodified",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "type",
  { data_type => "char", default_value => "r", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("id_role");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-12-27 04:58:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9Lyu+fyrb0n6sq1Q/m1nfg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->add_columns('lastmodified',
{ %{__PACKAGE__->column_info('lastmodified') },
set_on_create => 1,
set_on_update => 1
});

__PACKAGE__->meta->make_immutable;
1;
