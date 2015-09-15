use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::RoadsJun2015;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::RoadsJun2015

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<roads_jun_2015>

=cut

__PACKAGE__->table("roads_jun_2015");

=head1 ACCESSORS

=head2 objectid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'roads_jun_2015_objectid_seq'

=head2 fullname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 shield

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=head2 hwy_num

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 edit_date

  data_type: 'varchar'
  is_nullable: 1
  size: 11

=head2 fc_draft

  data_type: 'smallint'
  is_nullable: 1

=head2 hseb

  data_type: 'smallint'
  is_nullable: 1

=head2 ramp

  data_type: 'integer'
  is_nullable: 1

=head2 ramp_alt

  data_type: 'integer'
  is_nullable: 1

=head2 countyfp

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 tlid

  data_type: 'double precision'
  is_nullable: 1

=head2 lfromadd

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 ltoadd

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 rfromadd

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 rtoadd

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 zipl

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 zipr

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 county

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 dynamap_id

  data_type: 'integer'
  is_nullable: 1

=head2 crs_shape_length_1

  data_type: 'double precision'
  is_nullable: 1

=head2 crs_shape_length

  data_type: 'double precision'
  is_nullable: 1

=head2 ct_id

  data_type: 'double precision'
  is_nullable: 1

=head2 mtfcc

  data_type: 'varchar'
  is_nullable: 1
  size: 6

=head2 ct_district

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=head2 shape_length

  data_type: 'double precision'
  is_nullable: 1

=head2 wkb_geometry

  data_type: 'geometry'
  is_nullable: 1
  size: '12816,3519'

=head2 geom

  data_type: 'geometry'
  is_nullable: 1
  size: '58896,16'

=cut

__PACKAGE__->add_columns(
  "objectid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "roads_jun_2015_objectid_seq",
  },
  "fullname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "shield",
  { data_type => "varchar", is_nullable => 1, size => 2 },
  "hwy_num",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "edit_date",
  { data_type => "varchar", is_nullable => 1, size => 11 },
  "fc_draft",
  { data_type => "smallint", is_nullable => 1 },
  "hseb",
  { data_type => "smallint", is_nullable => 1 },
  "ramp",
  { data_type => "integer", is_nullable => 1 },
  "ramp_alt",
  { data_type => "integer", is_nullable => 1 },
  "countyfp",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "tlid",
  { data_type => "double precision", is_nullable => 1 },
  "lfromadd",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "ltoadd",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "rfromadd",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "rtoadd",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "zipl",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "zipr",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "county",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "dynamap_id",
  { data_type => "integer", is_nullable => 1 },
  "crs_shape_length_1",
  { data_type => "double precision", is_nullable => 1 },
  "crs_shape_length",
  { data_type => "double precision", is_nullable => 1 },
  "ct_id",
  { data_type => "double precision", is_nullable => 1 },
  "mtfcc",
  { data_type => "varchar", is_nullable => 1, size => 6 },
  "ct_district",
  { data_type => "varchar", is_nullable => 1, size => 3 },
  "shape_length",
  { data_type => "double precision", is_nullable => 1 },
  "wkb_geometry",
  { data_type => "geometry", is_nullable => 1, size => "12816,3519" },
  "geom",
  { data_type => "geometry", is_nullable => 1, size => "58896,16" },
);

=head1 PRIMARY KEY

=over 4

=item * L</objectid>

=back

=cut

__PACKAGE__->set_primary_key("objectid");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-14 10:38:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vKYpC9MxWhqrSeR6+N13VQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
