use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::Way;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::Way

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ways>

=cut

__PACKAGE__->table("ways");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_nullable: 0

=head2 version

  data_type: 'integer'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_nullable: 0

=head2 tstamp

  data_type: 'timestamp'
  is_nullable: 0

=head2 changeset_id

  data_type: 'bigint'
  is_nullable: 0

=head2 tags

  data_type: 'hstore'
  is_nullable: 1

=head2 nodes

  data_type: 'bigint[]'
  is_nullable: 1

=head2 bbox

  data_type: 'geometry'
  is_nullable: 1
  size: '58876,16'

=head2 linestring

  data_type: 'geometry'
  is_nullable: 1
  size: '58876,16'

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_nullable => 0 },
  "version",
  { data_type => "integer", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 0 },
  "tstamp",
  { data_type => "timestamp", is_nullable => 0 },
  "changeset_id",
  { data_type => "bigint", is_nullable => 0 },
  "tags",
  { data_type => "hstore", is_nullable => 1 },
  "nodes",
  { data_type => "bigint[]", is_nullable => 1 },
  "bbox",
  { data_type => "geometry", is_nullable => 1, size => "58876,16" },
  "linestring",
  { data_type => "geometry", is_nullable => 1, size => "58876,16" },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-23 21:39:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4+APHgbQFDbMp9kpwerqLw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
