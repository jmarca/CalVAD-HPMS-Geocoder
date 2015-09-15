use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::CrsIndex;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::CrsIndex

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<crs_index>

=cut

__PACKAGE__->table("crs_index");

=head1 ACCESSORS

=head2 ogc_fid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crs_index_ogc_fid_seq'

=head2 area

  data_type: 'numeric'
  is_nullable: 1
  size: [16,3]

=head2 perimeter

  data_type: 'numeric'
  is_nullable: 1
  size: [16,3]

=head2 crsindex_

  data_type: 'numeric'
  is_nullable: 1
  size: [11,0]

=head2 crsindex_i

  data_type: 'numeric'
  is_nullable: 1
  size: [11,0]

=head2 gpnum

  data_type: 'numeric'
  is_nullable: 1
  size: [2,0]

=head2 gpletter

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 group

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 listed

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 have

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 letter

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 cell

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 request

  data_type: 'numeric'
  is_nullable: 1
  size: [4,0]

=head2 annomethod

  data_type: 'numeric'
  is_nullable: 1
  size: [4,0]

=head2 arterial_p

  data_type: 'numeric'
  is_nullable: 1
  size: [4,0]

=head2 wkb_geometry

  data_type: 'geometry'
  is_nullable: 1
  size: '12808,3519'

=head2 geom

  data_type: 'geometry'
  is_nullable: 1
  size: '58888,16'

=cut

__PACKAGE__->add_columns(
  "ogc_fid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crs_index_ogc_fid_seq",
  },
  "area",
  { data_type => "numeric", is_nullable => 1, size => [16, 3] },
  "perimeter",
  { data_type => "numeric", is_nullable => 1, size => [16, 3] },
  "crsindex_",
  { data_type => "numeric", is_nullable => 1, size => [11, 0] },
  "crsindex_i",
  { data_type => "numeric", is_nullable => 1, size => [11, 0] },
  "gpnum",
  { data_type => "numeric", is_nullable => 1, size => [2, 0] },
  "gpletter",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "group",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "listed",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "have",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "letter",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "cell",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "request",
  { data_type => "numeric", is_nullable => 1, size => [4, 0] },
  "annomethod",
  { data_type => "numeric", is_nullable => 1, size => [4, 0] },
  "arterial_p",
  { data_type => "numeric", is_nullable => 1, size => [4, 0] },
  "wkb_geometry",
  { data_type => "geometry", is_nullable => 1, size => "12808,3519" },
  "geom",
  { data_type => "geometry", is_nullable => 1, size => "58888,16" },
);

=head1 PRIMARY KEY

=over 4

=item * L</ogc_fid>

=back

=cut

__PACKAGE__->set_primary_key("ogc_fid");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-14 10:38:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H20NRtQ4LFIkTgm15nJ7bQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
