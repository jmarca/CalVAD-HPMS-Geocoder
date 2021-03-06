use Test::Modern; # see done_testing()
use Carp;
use Data::Dumper;
use Config::Any; # config db credentials with config.json


use DBI;

use CalVAD::HPMS::Geocoder::Schema;
use CalVAD::HPMS::Geocoder;

ok(1,'use okay passed');



##################################################
# read the config file
##################################################
my $config_file = './test.config.json';
my $cfg = {};

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
    carp "no config file $config_file found";
}


##################################################
# translate config file into variables, for command line override
##################################################

my $path     = $cfg->{'path'};
my $help;

my $user = $cfg->{'postgresql'}->{'auth'}->{'username'} || q{};
# never use a postgres password, use config file or .pgpass
my $host = $cfg->{'postgresql'}->{'host'} || '127.0.0.1';
my $dbname =
    $cfg->{'postgresql'}->{'geocodedb'};

my $port = $cfg->{'postgresql'}->{'port'} || 5432;


my $admindb = $cfg->{'postgresql'}->{'admin'}->{'db'} || 'postgres';
my $adminuser = $cfg->{'postgresql'}->{'admin'}->{'user'} || 'postgres';


isnt($port,undef,'need a valid pg port defined in config file');
isnt($user,undef,'need a valid pg user defined in config file');
isnt($dbname,undef,'need a valid pg db defined in config file');
isnt($host,undef,'need a valid pg host defined in config file');

##################################################
# create testing database in 02 test
##################################################

# make a geocoder
my $geocoder = object_ok(
    sub {
        CalVAD::HPMS::Geocoder->new(
            # first the sql role
            'host_psql'     => $host,
            'port_psql'     => $port,
            'dbname_psql'   => $dbname,
            'username_psql' => $user,
            );
    },
    '$geocoder',
    isa   => [qw( CalVAD::HPMS::Geocoder Moose::Object )],
    does  => [qw( DB::Connection )],
    can   => [qw( get_roadway_section_osm )],
    # clean => 1,
    more  => sub {
        my $object = shift;
        isa_ok($object->_connection_psql, 'CalVAD::HPMS::Geocoder::Schema');
    },
    );

# try geocoding something

my @result = $geocoder->get_roadway_section_osm(
    'to' => 'DIAGONAL 254',
    'locality' => '06107',
    'road' => 'AVENUE 116',
    'from' => 'ROAD 264'
    );

is($result[0],'Avenue 116');
is($result[2],'0102000020E61000000D000000AAF5D95C90C05DC092544BDF10004240F63D8FF664C05DC0AB9C514E0F00424086600B3062C05DC00FB8AE98110042400415FA0560C05DC0F683150214004240EB4DB10F57C05DC0E54C6E6F120042400C94145800C05DC026E0D748120042407E569929ADBF5DC0E0675C381000424014ECBFCE4DBF5DC0469561DC0D004240CA1B60E63BBF5DC037FA980F08004240FF3F4E9830BF5DC0EFC8586DFEFF41407F9B6AD212BF5DC0CF21BAB1EAFF41409262DBFD05BF5DC04AF7297DD7FF4140BA2B60A7FDBE5DC0363A8CEEC5FF4140');
is($result[1],1.42833243170781);

@result = $geocoder->get_roadway_section_osm(
    'from' => 'DIAGONAL 254',
    'locality' => '06107',
    'road' => 'AVENUE 116',
    'to' => 'ROAD 264'
    );

is($result[0],'Avenue 116','from to ordering should not matter');
is($result[1],1.42833243170781,'from to ordering should not matter');



# problems:

# $VAR1 = {
#           'from' => 'MISSION ST',
#           'locality' => '06075',
#           'road' => 'OTIS ST',
#           'to' => 'MISSION ST'
#         };

# I observed that the above query uses gobs of RAM
# perhaps need an upper bound to the route building thing?

# $VAR1 = {
#           'road' => 'KING ST',
#           'to' => 'THE EMBARCADERO',
#           'from' => 'SECOND ST',
#           'locality' => '06075'
#         };


# $VAR1 = {
#           'locality' => '06037',
#           'from' => 'BOUQUET CANYON RD',
#           'road' => 'MAIN ST',
#           'to' => '15TH ST'
#         };

done_testing;



END{
    eval{
        my $dbh = DBI->connect("dbi:Pg:dbname=$admindb;host=$host;port=$port", $adminuser);
        $dbh->do("drop database $dbname");
    };
    if($@){
        carp $@;
    }
}
