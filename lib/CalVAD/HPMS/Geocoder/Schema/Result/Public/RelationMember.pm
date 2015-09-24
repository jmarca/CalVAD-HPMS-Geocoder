use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::RelationMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::RelationMember

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<relation_members>

=cut

__PACKAGE__->table("relation_members");

=head1 ACCESSORS

=head2 relation_id

  data_type: 'bigint'
  is_nullable: 0

=head2 member_id

  data_type: 'bigint'
  is_nullable: 0

=head2 member_type

  data_type: 'char'
  is_nullable: 0
  size: 1

=head2 member_role

  data_type: 'text'
  is_nullable: 0

=head2 sequence_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "relation_id",
  { data_type => "bigint", is_nullable => 0 },
  "member_id",
  { data_type => "bigint", is_nullable => 0 },
  "member_type",
  { data_type => "char", is_nullable => 0, size => 1 },
  "member_role",
  { data_type => "text", is_nullable => 0 },
  "sequence_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</relation_id>

=item * L</sequence_id>

=back

=cut

__PACKAGE__->set_primary_key("relation_id", "sequence_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-23 21:39:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o+zQz7W5BdtiIn50j2QB2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
