package OntoExtract::Schema::Result::Certainty;

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

OntoExtract::Schema::Result::Certainty

=cut

__PACKAGE__->table("certainty");

=head1 ACCESSORS

=head2 id_certainty

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 id_from

  data_type: 'bigint'
  is_nullable: 1

=head2 id_to

  data_type: 'bigint'
  is_nullable: 0

=head2 from_flag

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 to_flag

  data_type: 'char'
  is_nullable: 0
  size: 1

=head2 method_certainty

  data_type: 'integer'
  is_nullable: 0

=head2 final_certainty

  data_type: 'integer'
  is_nullable: 0

=head2 nr_hits

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_certainty",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "id_from",
  { data_type => "bigint", is_nullable => 1 },
  "id_to",
  { data_type => "bigint", is_nullable => 0 },
  "from_flag",
  { data_type => "char", is_nullable => 1, size => 1 },
  "to_flag",
  { data_type => "char", is_nullable => 0, size => 1 },
  "method_certainty",
  { data_type => "integer", is_nullable => 0 },
  "final_certainty",
  { data_type => "integer", is_nullable => 0 },
  "nr_hits",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id_certainty");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-12-27 03:52:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sUasZ+g9ONVe7uNBAm4epQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
