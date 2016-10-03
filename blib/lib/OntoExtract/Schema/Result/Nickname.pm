package OntoExtract::Schema::Result::Nickname;

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

OntoExtract::Schema::Result::Nickname

=cut

__PACKAGE__->table("nickname");

=head1 ACCESSORS

=head2 id_nickname

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 fromwho_flag

  data_type: 'char'
  is_nullable: 0
  size: 1

=head2 fromwho_id

  data_type: 'bigint'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 name_valid

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 type

  data_type: 'char'
  default_value: 'n'
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "id_nickname",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "fromwho_flag",
  { data_type => "char", is_nullable => 0, size => 1 },
  "fromwho_id",
  { data_type => "bigint", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "name_valid",
  { data_type => "char", is_nullable => 1, size => 1 },
  "type",
  { data_type => "char", default_value => "n", is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("id_nickname");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-12-27 09:33:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RN4awMlTQ+rTh/yAV4g3MQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
