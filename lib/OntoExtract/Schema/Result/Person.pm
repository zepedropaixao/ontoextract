package OntoExtract::Schema::Result::Person;

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

OntoExtract::Schema::Result::Person

=cut

__PACKAGE__->table("person");

=head1 ACCESSORS

=head2 id_person

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

=head2 sex

  data_type: 'char'
  default_value: 'u'
  is_nullable: 1
  size: 10

=head2 sex_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 title_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 picture

  data_type: 'text'
  is_nullable: 1

=head2 picture_valid

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

=head2 address

  data_type: 'text'
  is_nullable: 1

=head2 address_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 birthday

  data_type: 'date'
  is_nullable: 1

=head2 birthday_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 deathday

  data_type: 'date'
  is_nullable: 1

=head2 deathday_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 criminalrecord

  data_type: 'text'
  is_nullable: 1

=head2 criminalrecord_valid

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
  default_value: 'p'
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "id_person",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "name_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "sex",
  { data_type => "char", default_value => "u", is_nullable => 1, size => 10 },
  "sex_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "title_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "picture",
  { data_type => "text", is_nullable => 1 },
  "picture_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "country",
  { data_type => "text", is_nullable => 1 },
  "country_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "address",
  { data_type => "text", is_nullable => 1 },
  "address_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "birthday",
  { data_type => "date", is_nullable => 1 },
  "birthday_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "deathday",
  { data_type => "date", is_nullable => 1 },
  "deathday_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "criminalrecord",
  { data_type => "text", is_nullable => 1 },
  "criminalrecord_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "abstract",
  { data_type => "text", is_nullable => 1 },
  "abstract_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "articlelink",
  { data_type => "text", is_nullable => 1 },
  "articlelink_valid",
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
  { data_type => "char", default_value => "p", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("id_person");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-12-27 04:58:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3U0Yt+Z3usJ6HdzHIGbJQQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->add_columns('lastmodified',
{ %{__PACKAGE__->column_info('lastmodified') },
set_on_create => 1,
set_on_update => 1
});

__PACKAGE__->meta->make_immutable;
1;
