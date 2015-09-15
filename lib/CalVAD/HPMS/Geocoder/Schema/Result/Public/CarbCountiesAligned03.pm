use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::CarbCountiesAligned03;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::CarbCountiesAligned03

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<carb_counties_aligned_03>

=cut

__PACKAGE__->table("carb_counties_aligned_03");

=head1 ACCESSORS

=head2 gid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'carb_counties_aligned_03_gid_seq'

=head2 cacoa_

  data_type: 'integer'
  is_nullable: 1

=head2 cacoa_id

  data_type: 'integer'
  is_nullable: 1

=head2 coname

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 conum

  data_type: 'smallint'
  is_nullable: 1

=head2 display

  data_type: 'smallint'
  is_nullable: 1

=head2 symbol

  data_type: 'bigint'
  is_nullable: 1

=head2 islandname

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 baysplinte

  data_type: 'varchar'
  is_nullable: 1
  size: 35

=head2 cntyi_area

  data_type: 'numeric'
  is_nullable: 1

=head2 island_id

  data_type: 'smallint'
  is_nullable: 1

=head2 bay_id

  data_type: 'smallint'
  is_nullable: 1

=head2 the_geom

  data_type: 'geometry'
  is_nullable: 1

=head2 geom4326

  data_type: 'geometry'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "gid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "carb_counties_aligned_03_gid_seq",
  },
  "cacoa_",
  { data_type => "integer", is_nullable => 1 },
  "cacoa_id",
  { data_type => "integer", is_nullable => 1 },
  "coname",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "conum",
  { data_type => "smallint", is_nullable => 1 },
  "display",
  { data_type => "smallint", is_nullable => 1 },
  "symbol",
  { data_type => "bigint", is_nullable => 1 },
  "islandname",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "baysplinte",
  { data_type => "varchar", is_nullable => 1, size => 35 },
  "cntyi_area",
  { data_type => "numeric", is_nullable => 1 },
  "island_id",
  { data_type => "smallint", is_nullable => 1 },
  "bay_id",
  { data_type => "smallint", is_nullable => 1 },
  "the_geom",
  { data_type => "geometry", is_nullable => 1 },
  "geom4326",
  { data_type => "geometry", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gid>

=back

=cut

__PACKAGE__->set_primary_key("gid");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-14 10:40:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m4pV4Sl91seek7wmuQbL0w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
