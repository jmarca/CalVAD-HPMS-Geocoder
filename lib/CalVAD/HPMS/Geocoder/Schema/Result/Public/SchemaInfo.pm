use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::SchemaInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::SchemaInfo

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<schema_info>

=cut

__PACKAGE__->table("schema_info");

=head1 ACCESSORS

=head2 version

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns("version", { data_type => "integer", is_nullable => 0 });

=head1 PRIMARY KEY

=over 4

=item * L</version>

=back

=cut

__PACKAGE__->set_primary_key("version");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-23 21:39:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4l+jP55NkPPPbF+PDIP52w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
