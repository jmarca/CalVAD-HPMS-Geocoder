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
use lib "$FindBin::Bin/lib";

use CalVAD::HPMS::Extractor;
use CalVAD::HPMS::Geocoder;

use Try::Tiny;

use Getopt::Long;
use Config::Any;
use Pod::Usage;

## Options are mostly set in the config file

my $config_file = './config.json';

my $help;

my $county = 0;
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

my $geocoder = CalVAD::HPMS::Geocoder->new(

    # first the sql role
    'host_psql'     => $osm_host,
    'port_psql'     => $osm_port,
    'dbname_psql'   => $osm_dbname,
    'username_psql' => $osm_user,
    'shwy'          => $shwy,
    'county'        => $county,
);

# quick test to make sure everything is hunky dunky

my $ways = $geocoder->resultset('Public::Way')->count();
carp "db has $ways ways";

# make sure the geocoder function exists and is up to date
my @matching_function =  ("psql",
                          "-d", "$osm_dbname",
                          "-U", "$osm_user",
                          "-h", "$osm_host",
                          "-p", "$osm_port",
                          "-f", "./sql/find_road_osm_trigram.sql");
my @pg_trigram_args =  ("psql",
                              "-d", "$osm_dbname",
                              "-U", "$osm_user",
                              "-h", "$osm_host",
                              "-p", "$osm_port",
                              "-c", "CREATE EXTENSION pg_trgm;");


system(@matching_function) == 0
    or croak "system @matching_function failed: $?";

system(@pg_trigram_args) == 0
    or croak "system @pg_trigram_args failed: $?";



sub geometry_handler {
    my ( $records, $geocoder ) = @_;
    # my $km_to_miles = 0.621371192;
    return sub {
        my (@vals)   = @_;
        # carp Dumper \@vals;
        my $fips     = $vals[7];
        my $pad_char = '0';
        my $pad_len  = 3;
        my $locality = '06' . $pad_char x ( $pad_len - length($fips) ) . $fips;

        # get the from to stuff
        my $fromto = $extractor->guess_name_to_from(\@vals);


        my @result;
        my $geom;
        if($fromto->{'name'} && $fromto->{'from'} && $fromto->{'to'})
        {
            carp Dumper {        'locality' => $locality,
                                 'road'     => $fromto->{'name'},
                                 'from'     => $fromto->{'from'},
                                 'to'       => $fromto->{'to'},
            };
            if ( !$shwy ) {
                @result = $geocoder->get_roadway_section_osm(
                    'locality' => $locality,
                    'road'     => $fromto->{'name'},
                    'from'     => $fromto->{'from'},
                    'to'       => $fromto->{'to'},
                    );
            }
            else {
                croak 'highways should not be handled here';
            }
            $geom = $result[2];
            if ( $result[1] ) {

                # maybe put in code here to diagnose whether the lengths match up
                my $hpms_length = $vals[11] ;
                if ( ( $hpms_length - $result[1] )**2 / $hpms_length > 0.1 ) {
                    carp
                        "lengths are different:  hpms is $hpms_length, OSM match is $result[1]";
                }
                else {
                    carp
                        "lengths compare ok:  hpms is $hpms_length, OSM match is $result[1]";
                }

                my $geocode_res = $extractor->save_geocode_results(
                    'hpmsid'=>$vals[0],
                    'direction'=>'',
                    'intended_name'=>$fromto->{'name'},
                    'intended_from'=>$fromto->{'from'},
                    'intended_to'  =>$fromto->{'to'},
                    'matched_name' =>$result[0],
                    'matched_from' =>$result[3],
                    'matched_to'   =>$result[4],
                    );

            }
        }

        #
        # so see, perl is sucky because it will block here while the
        # save is being done.
        #

        # save the geometry to a table with the @vals information
        my $geom_result = $extractor->create_geometry($vals[0],'',$geom);

        return $geom_result;

    };
}

my $stop = 2;
my $counter          = 0;
my $choked           = 0;
my $failed           = 0;
my $hpms_row_handler = sub {

    my ($rs) = @_;
    $counter = 0;
    $failed = 0;
    $choked = 0;
    my $cursor      = $rs->cursor;
    my $records     = [];
    my $geo_handler = geometry_handler( $records, $geocoder );

    while ( my @vals = $cursor->next ) {

        #carp Dumper \@vals;

        my $test_eval = eval {

            my $res = $geo_handler->(@vals);
            if ($res == 0){
                carp 'problem with ',Dumper \@vals;
            }
            if($res == -1){
                $failed++;
            }
        };
        if ($EVAL_ERROR) {    # find or create failed
            carp "can't process record $vals[0], $EVAL_ERROR";
            $choked++;
            my $geom_result2 = $extractor->create_geometry($vals[0],'',undef);
        }
        $counter++;
    }
};

my $rs = $extractor->extract_out($hpms_row_handler);

while ($counter) {
    carp "processed $counter, $failed did not match geometries, $choked failed completely";

    $rs = $extractor->extract_out($hpms_row_handler);

    # loop until done
    # or stop hits zero
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
