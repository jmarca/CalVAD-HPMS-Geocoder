use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::RasterOverview;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::RasterOverview

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<raster_overviews>

=cut

__PACKAGE__->table("raster_overviews");

=head1 ACCESSORS

=head2 o_table_catalog

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 o_table_schema

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 o_table_name

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 o_raster_column

  data_type: 'name'
  is_nullable: 1
  size: 64

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

=head2 overview_factor

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "o_table_catalog",
  { data_type => "name", is_nullable => 1, size => 64 },
  "o_table_schema",
  { data_type => "name", is_nullable => 1, size => 64 },
  "o_table_name",
  { data_type => "name", is_nullable => 1, size => 64 },
  "o_raster_column",
  { data_type => "name", is_nullable => 1, size => 64 },
  "r_table_catalog",
  { data_type => "name", is_nullable => 1, size => 64 },
  "r_table_schema",
  { data_type => "name", is_nullable => 1, size => 64 },
  "r_table_name",
  { data_type => "name", is_nullable => 1, size => 64 },
  "r_raster_column",
  { data_type => "name", is_nullable => 1, size => 64 },
  "overview_factor",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-23 21:39:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e5c3fZuYI0wh/Y1zdjx72A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
