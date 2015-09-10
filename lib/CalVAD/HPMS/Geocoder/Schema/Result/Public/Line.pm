use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::Line;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::Line

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<lines>

=cut

__PACKAGE__->table("lines");

=head1 ACCESSORS

=head2 ogc_fid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'lines_ogc_fid_seq'

=head2 osm_id

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 highway

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 waterway

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 aerialway

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 barrier

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 man_made

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 z_order

  data_type: 'integer'
  is_nullable: 1

=head2 other_tags

  data_type: 'hstore'
  is_nullable: 1

=head2 wkb_geometry

  data_type: 'geometry'
  is_nullable: 1
  size: '58884,16'

=cut

__PACKAGE__->add_columns(
  "ogc_fid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "lines_ogc_fid_seq",
  },
  "osm_id",
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
  "highway",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "waterway",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "aerialway",
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
  "man_made",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "z_order",
  { data_type => "integer", is_nullable => 1 },
  "other_tags",
  { data_type => "hstore", is_nullable => 1 },
  "wkb_geometry",
  { data_type => "geometry", is_nullable => 1, size => "58884,16" },
);

=head1 PRIMARY KEY

=over 4

=item * L</ogc_fid>

=back

=cut

__PACKAGE__->set_primary_key("ogc_fid");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-10 14:46:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:azzt97G5zTUvYm5eEA4h8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
