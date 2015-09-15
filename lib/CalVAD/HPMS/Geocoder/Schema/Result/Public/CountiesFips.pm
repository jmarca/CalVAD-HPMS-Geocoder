use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::CountiesFips;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::CountiesFips

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<counties_fips>

=cut

__PACKAGE__->table("counties_fips");

=head1 ACCESSORS

=head2 fips

  data_type: 'varchar'
  is_nullable: 0
  size: 5

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "fips",
  { data_type => "varchar", is_nullable => 0, size => 5 },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</fips>

=back

=cut

__PACKAGE__->set_primary_key("fips");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-14 11:08:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fCOHDuikIoSu5WrFpOGV1w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
