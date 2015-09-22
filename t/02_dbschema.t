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
# create testing database
##################################################

my $admin_dbh;
eval{
    $admin_dbh = DBI->connect("dbi:Pg:dbname=$admindb;host=$host;port=$port", $adminuser);
};
if($@) {
    carp 'must have valid admin credentials in test.config.json, and a valid admin password setup in .pgpass file';
    croak $@;
}

my $create = "create database $dbname";
if($user ne $adminuser){
    $create .= " with owner $user";
}
eval {
        $admin_dbh->do($create);
};
if($@) {
    carp 'test db creation failed';
    carp $@;
    carp Dumper [
        'host_psql'=>$host,
        'port_psql'=>$port,
        'dbname_psql'=>$dbname,
        'admin database'=>$admindb,
        'admin user'=>$adminuser,
        ];

    croak 'failed to create test database';
}

## deploy required tables via DBIx::Class

## deploy just the tables I'm going to be accessing during testing

## create postgis extensions
my $postgis_args =  ["psql",
                      "-d", "$dbname",
                      "-U", "$user",
                      "-h", "$host",
                      "-p", "$port",
                     "-c", "CREATE EXTENSION postgis;"];

# topology not strictly necessary
my $postgis_topology_args =  ["psql",
                              "-d", "$dbname",
                              "-U", "$user",
                              "-h", "$host",
                              "-p", "$port",
                              "-c", "CREATE EXTENSION postgis_topology;"];
my $db_deploy_args = ["pg_restore",
                      "-d", "$dbname",
                      "-U", "$user",
                      "-h", "$host",
                      "-p", "$port",
                      "./sql/geocode_test_db"];

for my $args ( $postgis_args, $postgis_topology_args, $db_deploy_args)
{
    my @sysargs = @{$args};
    system(@sysargs) == 0
      or croak "system @sysargs failed: $?";
}

# make a geocoder
my $geocoder  = CalVAD::HPMS::Geocoder->new(

    # first the sql role
    'host_psql'     => $host,
    'port_psql'     => $port,
    'dbname_psql'   => $dbname,
    'username_psql' => $user,

);

isnt($geocoder, undef, 'object creation should work with all required fields');
isa_ok($geocoder,'CalVAD::HPMS::Geocoder','geocoder is an geocoder');

my $connect;
eval {
  $connect = $geocoder->_connection_psql;
};
if($@) {
  carp $@;
}

isnt($connect, undef, 'db connection should be possible');
isa_ok($connect,'CalVAD::HPMS::Geocoder::Schema','db connection is right class');

# test simple query works

my $rs = $geocoder->resultset('Public::Line');
isa_ok($rs,'DBIx::Class::ResultSet','got a result set');
my @all = $rs->all();
is(@all,39860,'got all lines expected');

$rs = $geocoder->resultset('Public::Point');
isa_ok($rs,'DBIx::Class::ResultSet','got a result set');
@all = $rs->all();
is(@all,8601,'got all points expected');

$rs = $geocoder->resultset('Public::CrsIndex');
isa_ok($rs,'DBIx::Class::ResultSet','got a result set');
@all = $rs->all();
is(@all,91,'got all CRS grids expected');

$rs = $geocoder->resultset('Public::RoadsJun2015');
isa_ok($rs,'DBIx::Class::ResultSet','got a result set');
@all = $rs->all();
is(@all,59733,'got all CRS roads expected');

$rs = $geocoder->resultset('Public::CarbCountiesAligned03');
isa_ok($rs,'DBIx::Class::ResultSet','got a result set');
my @some = $rs->search(
    {
        name => 'TULARE'
    }
);
is(@some,1,'got Tulare county shape');

$rs = $geocoder->resultset('Public::CountiesFips');
isa_ok($rs,'DBIx::Class::ResultSet','got a result set');
@some = $rs->search(
    {
        fips => '06107'
    }
);
is(@some,1,'got Tulare county from fips code');
is($some[0]->name,'Tulare','Got Tulare county from fips code');


done_testing;



END{
    # $connect = undef;
    # $obj = undef;
    eval{
        my $dbh = DBI->connect("dbi:Pg:dbname=$admindb;host=$host;port=$port", $adminuser);
        $dbh->do("drop database $dbname");
    };
    if($@){
        carp $@;
    }
}
