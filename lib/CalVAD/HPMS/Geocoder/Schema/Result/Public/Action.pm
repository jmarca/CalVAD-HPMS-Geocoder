use utf8;
package CalVAD::HPMS::Geocoder::Schema::Result::Public::Action;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CalVAD::HPMS::Geocoder::Schema::Result::Public::Action

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<actions>

=cut

__PACKAGE__->table("actions");

=head1 ACCESSORS

=head2 data_type

  data_type: 'char'
  is_nullable: 0
  size: 1

=head2 action

  data_type: 'char'
  is_nullable: 0
  size: 1

=head2 id

  data_type: 'bigint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "data_type",
  { data_type => "char", is_nullable => 0, size => 1 },
  "action",
  { data_type => "char", is_nullable => 0, size => 1 },
  "id",
  { data_type => "bigint", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</data_type>

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("data_type", "id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-23 21:39:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FrWieDnVGuIO+N0XgJLt7g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
