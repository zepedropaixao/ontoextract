package OntoExtract::Schema::Result::News;

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

OntoExtract::Schema::Result::News

=cut

__PACKAGE__->table("news");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 status

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 timestamp

  data_type: 'datetime'
  is_nullable: 1

=head2 pubdate

  data_type: 'datetime'
  is_nullable: 1

=head2 source

  data_type: 'text'
  is_nullable: 1

=head2 author

  data_type: 'text'
  is_nullable: 1

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 content

  data_type: 'text'
  is_nullable: 1

=head2 tags

  data_type: 'text'
  is_nullable: 1

=head2 page_url

  data_type: 'text'
  is_nullable: 1

=head2 feed_url

  data_type: 'text'
  is_nullable: 1

=head2 image_url

  data_type: 'text'
  is_nullable: 1

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 lang

  data_type: 'varchar'
  is_nullable: 1
  size: 8

=head2 geo

  data_type: 'text'
  is_nullable: 1

=head2 hostname

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "status",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "timestamp",
  { data_type => "datetime", is_nullable => 1 },
  "pubdate",
  { data_type => "datetime", is_nullable => 1 },
  "source",
  { data_type => "text", is_nullable => 1 },
  "author",
  { data_type => "text", is_nullable => 1 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "content",
  { data_type => "text", is_nullable => 1 },
  "tags",
  { data_type => "text", is_nullable => 1 },
  "page_url",
  { data_type => "text", is_nullable => 1 },
  "feed_url",
  { data_type => "text", is_nullable => 1 },
  "image_url",
  { data_type => "text", is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "lang",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "geo",
  { data_type => "text", is_nullable => 1 },
  "hostname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-11-15 14:56:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZVg1HwBwH2+Lyb/bAx1xrA


# You can replace this text with custom content, and it will be preserved on regeneration

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/Core/);

1;
