package OntoExtract::Schema::Result::Organization;

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

OntoExtract::Schema::Result::Organization

=cut

__PACKAGE__->table("organization");

=head1 ACCESSORS

=head2 id_organization

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 name_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 logo

  data_type: 'text'
  is_nullable: 1

=head2 logo_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 country

  data_type: 'text'
  is_nullable: 1

=head2 country_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 hqaddress

  data_type: 'text'
  is_nullable: 1

=head2 hqaddress_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 foundationday

  data_type: 'date'
  is_nullable: 1

=head2 foundationday_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 endday

  data_type: 'date'
  is_nullable: 1

=head2 endday_valid

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

=head2 slogan

  data_type: 'text'
  is_nullable: 1

=head2 slogan_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 tagharem

  data_type: 'text'
  is_nullable: 1

=head2 tagharem_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=head2 incompleteflag

  data_type: 'char'
  default_value: 't'
  is_nullable: 0
  size: 10

=head2 lastmodified

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 type

  data_type: 'char'
  default_value: 'o'
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "id_organization",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "name_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "logo",
  { data_type => "text", is_nullable => 1 },
  "logo_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "country",
  { data_type => "text", is_nullable => 1 },
  "country_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "hqaddress",
  { data_type => "text", is_nullable => 1 },
  "hqaddress_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "foundationday",
  { data_type => "date", is_nullable => 1 },
  "foundationday_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "endday",
  { data_type => "date", is_nullable => 1 },
  "endday_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "abstract",
  { data_type => "text", is_nullable => 1 },
  "abstract_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "articlelink",
  { data_type => "text", is_nullable => 1 },
  "articlelink_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "slogan",
  { data_type => "text", is_nullable => 1 },
  "slogan_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "tagharem",
  { data_type => "text", is_nullable => 1 },
  "tagharem_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
  "incompleteflag",
  { data_type => "char", default_value => "t", is_nullable => 0, size => 10 },
  "lastmodified",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "type",
  { data_type => "char", default_value => "o", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("id_organization");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-12-27 04:58:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zOQ1VdhGVfHELRevjgE9qg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->add_columns('lastmodified',
{ %{__PACKAGE__->column_info('lastmodified') },
set_on_create => 1,
set_on_update => 1
});

__PACKAGE__->meta->make_immutable;
1;
