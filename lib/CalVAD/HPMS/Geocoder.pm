# ABSTRACT: turns baubles into trinkets
use strict;
use warnings;
use Moops;

package CalVAD::HPMS;

class Geocoder using Moose : ro {
    use Carp;
    use Data::Dumper;
    use English qw(-no_match_vars);
    use version; our $VERSION = qv('0.1.0');

    use CalVAD::HPMS::Geocoder::Schema;

    use DBI qw(:sql_types);
    use DBD::Pg  qw(:pg_types);

    has 'trigram' => (is => 'rw', isa => 'Bool', 'default'=>0);
    has 'shwy' => (is => 'rw', isa => 'Bool', 'default'=>0);
    has 'county' => (is => 'rw', isa => 'Bool', 'default'=>0);


}
1;
