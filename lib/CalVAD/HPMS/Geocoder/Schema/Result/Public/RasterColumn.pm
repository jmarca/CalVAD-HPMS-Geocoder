use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::RasterColumn;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::RasterColumn

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<raster_columns>

=cut

__PACKAGE__->table("raster_columns");

=head1 ACCESSORS

=head2 r_table_catalog

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 r_table_schema

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 r_table_name

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 r_raster_column

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 srid

  data_type: 'integer'
  is_nullable: 1

=head2 scale_x

  data_type: 'double precision'
  is_nullable: 1

=head2 scale_y

  data_type: 'double precision'
  is_nullable: 1

=head2 blocksize_x

  data_type: 'integer'
  is_nullable: 1

=head2 blocksize_y

  data_type: 'integer'
  is_nullable: 1

=head2 same_alignment

  data_type: 'boolean'
  is_nullable: 1

=head2 regular_blocking

  data_type: 'boolean'
  is_nullable: 1

=head2 num_bands

  data_type: 'integer'
  is_nullable: 1

=head2 pixel_types

  data_type: 'text[]'
  is_nullable: 1

=head2 nodata_values

  data_type: 'double precision[]'
  is_nullable: 1

=head2 out_db

  data_type: 'boolean[]'
  is_nullable: 1

=head2 extent

  data_type: 'geometry'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "r_table_catalog",
  { data_type => "name", is_nullable => 1, size => 64 },
  "r_table_schema",
  { data_type => "name", is_nullable => 1, size => 64 },
  "r_table_name",
  { data_type => "name", is_nullable => 1, size => 64 },
  "r_raster_column",
  { data_type => "name", is_nullable => 1, size => 64 },
  "srid",
  { data_type => "integer", is_nullable => 1 },
  "scale_x",
  { data_type => "double precision", is_nullable => 1 },
  "scale_y",
  { data_type => "double precision", is_nullable => 1 },
  "blocksize_x",
  { data_type => "integer", is_nullable => 1 },
  "blocksize_y",
  { data_type => "integer", is_nullable => 1 },
  "same_alignment",
  { data_type => "boolean", is_nullable => 1 },
  "regular_blocking",
  { data_type => "boolean", is_nullable => 1 },
  "num_bands",
  { data_type => "integer", is_nullable => 1 },
  "pixel_types",
  { data_type => "text[]", is_nullable => 1 },
  "nodata_values",
  { data_type => "double precision[]", is_nullable => 1 },
  "out_db",
  { data_type => "boolean[]", is_nullable => 1 },
  "extent",
  { data_type => "geometry", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-10 14:46:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5HqWBDJO6mPXekUEIEqj0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
