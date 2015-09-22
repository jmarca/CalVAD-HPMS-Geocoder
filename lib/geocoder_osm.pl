#!/usr/bin/perl -w

# this version uses the OSM routines.  Which I hope works better than the Census version.

use strict;
use warnings;
use Data::Dumper;
use version; our $VERSION = qv('0.0.1');
use English qw(-no_match_vars);
use Carp;
use Carp qw(cluck);
use FindBin;
use lib "$FindBin::Bin/../lib";

use HPMS::ExtractOut;
use Geocoder::Geocode;

use Try::Tiny;

use Getopt::Long;
use Config::Any;
use Pod::Usage;

## Options are mostly set in the config file

my $config_file = './config.json';

my $help;

my $county = 1;
my $shwy;
my $retry;

my $result = GetOptions(
    'help|?'  => \$help,
    'config'    => \$config_file,
    'retry'   => \$retry,
);

if ( !$result || $help ) {
    pod2usage(1);
}

my $cfg = {};

##################################################
# read the config file
##################################################

# check if right permissions on file, if so, use it
if( -e $config_file){
    my @mode = (stat($config_file));
    my $str_mode = sprintf "%04o", $mode[2];
    if( $str_mode == 100600 ){

        $cfg = Config::Any->load_files({files => [$config_file],
                                        flatten_to_hash=>1,
                                        use_ext => 1,
                                       });
        # simplify the hashref down to just the one file
        $cfg = $cfg->{$config_file};
    }else{
        croak "permissions for $config_file are $str_mode.  Set permissions to 0600 (only the user can read or write)";
    }
}
else{
  # if no config file, then just note that and move on
    carp "no config file $config_file found.  Stuff probably won't work";
}

##################################################
# translate config file into variables, for command line override
##################################################

my $path     = $cfg->{'path'};
my $help;

my $hpms_user = $cfg->{'postgresql'}->{'hpms'}->{'auth'}->{'username'} || q{};
# never use a postgres password, use config file or .pgpass
my $hpms_host = $cfg->{'postgresql'}->{'hpms'}->{'host'} || '127.0.0.1';
my $hpms_port = $cfg->{'postgresql'}->{'hpms'}->{'port'} || 5432;
my $hpms_dbname = $cfg->{'postgresql'}->{'hpms'}->{'dbname'};

my $osm_user = $cfg->{'postgresql'}->{'osm'}->{'auth'}->{'username'} || q{};
my $osm_host = $cfg->{'postgresql'}->{'osm'}->{'host'} || '127.0.0.1';
my $osm_port = $cfg->{'postgresql'}->{'osm'}->{'port'} || 5432;
my $osm_dbname = $cfg->{'postgresql'}->{'osm'}->{'dbname'};

my $extractor  = CalVAD::HPMS::Extractor->new(

    'host_psql'     => $hpms_host,
    'port_psql'     => $hpms_port,
    'dbname_psql'   => $hpms_dbname,
    'username_psql' => $hpms_user,
    'shwy'          => $shwy,
    'retry'         => $retry,

);

my $geocoder = Geocoder::Geocode->new(

    # first the sql role
    'host_psql'     => $osm_host,
    'port_psql'     => $osm_port,
    'dbname_psql'   => $osm_dbname,
    'username_psql' => $osm_user,
    'password_psql' => $osm_pass,
    'shwy'          => $shwy,
    'county'        => $county,
);

# to be run in a try block.  has croaks and stuff
my $insert_geom = sub {
    my ($records) = @_;
    my $new_join;
    my $test_eval;
    my $handled_hpms_records = {};

    for my $record ( @{$records} ) {

        # create the geometry
        my $direction = $record->[8];
        my $geom      = $record->[7];
        my $hpmsid    = $record->[0];
        my $res = $extractor->create_geometry($hpmsid,$direction,$geom);

        $handled_hpms_records->{"$hpmsid $direction"} = $res;

    }
};

sub geometry_handler {
    my ( $records, $geocoder ) = @_;
    # my $km_to_miles = 0.621371192;
    return sub {
        my (@vals)   = @_;
        my $fips     = $vals[4];
        my $pad_char = '0';
        my $pad_len  = 3;
        my $locality = '06' . $pad_char x ( $pad_len - length($fips) ) . $fips;

        my @result;
        my $geom;
        if ( !$shwy ) {
            @result = $geocoder->get_roadway_section_osm(
                'locality' => $locality,
                'road'     => $vals[5],
                'from'     => $vals[6],
                'to'       => $vals[7],
            );
        }
        else {
            croak 'highways should not be handled here';
        }
        $geom = $result[0];
        if ( $result[1] ) {

            # maybe put in code here to diagnose whether the lengths match up
            my $hpms_length =
              $vals[9] == 1 ? $vals[15] : $km_to_miles * $vals[15];
            if ( ( $hpms_length - $result[1] )**2 / $hpms_length > 0.1 ) {
                carp
"lengths are different:  hpms is $hpms_length, OSM match is $result[1] (is_metric=$vals[9])";
            }
            else {
                carp
"lengths compare ok:  hpms is $hpms_length, OSM match is $result[1] (is_metric=$vals[9])";
            }
        }

        # save the geometry to a table with the @vals information
        push @{$records}, [ @vals[ 0, 2, 3, 4, 5, 6, 7 ], $geom ];

    };
}

my $counter          = 0;
my $hpms_row_handler = sub {

    my ($rs) = @_;
    $counter = 0;
    my $cursor      = $rs->cursor;
    my $records     = [];
    my $geo_handler = geometry_handler( $records, $geocoder );

    while ( my @vals = $cursor->next ) {

        #carp Dumper \@vals;
        $geo_handler->(@vals);
        $counter++;
    }

    #carp Dumper $records;
    my $rs_txn;
    try {
        carp 'saving ', scalar @$records;
        $rs_txn = $extractor->txn_do( $insert_geom, $records );
    }
    catch {
        # Transaction failed
        if ( $_ =~ /Rollback failed/ ) {

            # Rollback failed
            croak "the sky is falling!";
        }
        carp $_;

        # deal_with_failed_transaction();
        carp 'dealing with failed transaction';
        while ( my $record = shift @{$records} ) {
            try {
                $rs_txn = $extractor->txn_do( $insert_geom, [$record] );
            }
            catch {
                # Transaction failed
                carp $_;
                if ( $_ =~ /Rollback failed/ ) {

                    # Rollback failed
                    croak "the sky is falling!";
                }

                # deal_with_failed_transaction();
                carp 'skipping transaction:', Dumper $record;
            }
        }
    }
};

my $rs = $extractor->extract_out($hpms_row_handler);

while ($counter) {
    carp "processed $counter";
    $rs = $extractor->extract_out($hpms_row_handler)

      # loop until done
}

1;

__END__


=head1 NAME

    geocoder.pl - match hpms data with tiger lines

=head1 VERSION

    this is the 1st perl version

=head1 USAGE

    perl -w lib/geocoder.pl  -shwy > hpms_geocoding_output.txt 2>&1 &



=head1 REQUIRED ARGUMENTS

none


=head1 OPTIONS

    -help     brief help message

    -config   the config file to use.  default is config.json

    -retry     optional boolean, default false if not set.  Whether to
               try again with records that were already added to the
               failed match table.



=head1 DIAGNOSTICS

=head1 EXIT STATUS

1


=head1 CONFIGURATION AND ENVIRONMENT

I'm not a big fan of passing usernames and passwords on the command
line.  These should be set in the config file and that file must be
set chmod 0600 so that only the owner can read and write to it

A sample config.json is:

{
    "couchdb": {
        "host": "127.0.0.1",
        "port":5984,
        "trackingdb":"vdsdata%2ftracking",
        "db":"vdsdata%2ftracking",
        "auth":{"username":"couchuser",
                "password":"couchpass"
               },
        "dbname":"testing",
        "design":"detectors",
        "view":"fips_year"
    },
    "postgresql": {
        "hpms":{
            "host": "127.0.0.1",
            "port":5432,
            "dbname":"crs_small2",
            "auth":{"username":"pguser"}
        },
        "osm":{
            "host": "127.0.0.1",
            "port":5432,
            "dbname":"crs_small2",
            "auth":{"username":"pguser"}
        }
    }
}


=head1 DEPENDENCIES

Dist::Zilla, which should then pick up all the other dependencies

=head1 INCOMPATIBILITIES

none known

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

James E. Marca, UC Irvine ITS
jmarca@translab.its.uci.edu
james@actvimetrics.com

=head1 LICENSE AND COPYRIGHT

This program is free software, (c) 2012--2015 James E Marca under the same terms as Perl itself.

=head1 DESCRIPTION

B<This program> will load HPMS records, then geocode them using OSM data.
