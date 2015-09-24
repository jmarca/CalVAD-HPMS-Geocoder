use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::WayNode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::WayNode

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<way_nodes>

=cut

__PACKAGE__->table("way_nodes");

=head1 ACCESSORS

=head2 way_id

  data_type: 'bigint'
  is_nullable: 0

=head2 node_id

  data_type: 'bigint'
  is_nullable: 0

=head2 sequence_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "way_id",
  { data_type => "bigint", is_nullable => 0 },
  "node_id",
  { data_type => "bigint", is_nullable => 0 },
  "sequence_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</way_id>

=item * L</sequence_id>

=back

=cut

__PACKAGE__->set_primary_key("way_id", "sequence_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-23 21:39:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wXcFHcNUPbx/mxVp6bVU+Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
