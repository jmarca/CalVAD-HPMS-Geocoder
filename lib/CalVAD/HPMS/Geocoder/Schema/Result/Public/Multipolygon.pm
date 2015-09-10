use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::Multipolygon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::Multipolygon

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<multipolygons>

=cut

__PACKAGE__->table("multipolygons");

=head1 ACCESSORS

=head2 ogc_fid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'multipolygons_ogc_fid_seq'

=head2 osm_id

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 osm_way_id

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 type

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 aeroway

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 amenity

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 admin_level

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 barrier

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 boundary

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 building

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 craft

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 geological

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 historic

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 land_area

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 landuse

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 leisure

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 man_made

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 military

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 natural

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 office

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 place

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 shop

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 sport

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 tourism

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 other_tags

  data_type: 'hstore'
  is_nullable: 1

=head2 wkb_geometry

  data_type: 'geometry'
  is_nullable: 1
  size: '58900,16'

=cut

__PACKAGE__->add_columns(
  "ogc_fid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "multipolygons_ogc_fid_seq",
  },
  "osm_id",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "osm_way_id",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "type",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "aeroway",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "amenity",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "admin_level",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "barrier",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "boundary",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "building",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "craft",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "geological",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "historic",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "land_area",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "landuse",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "leisure",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "man_made",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "military",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "natural",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "office",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "place",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "shop",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "sport",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "tourism",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "other_tags",
  { data_type => "hstore", is_nullable => 1 },
  "wkb_geometry",
  { data_type => "geometry", is_nullable => 1, size => "58900,16" },
);

=head1 PRIMARY KEY

=over 4

=item * L</ogc_fid>

=back

=cut

__PACKAGE__->set_primary_key("ogc_fid");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-10 14:46:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jJXV3tYq+7xwCXhHM/9QVA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
