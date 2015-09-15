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

        my $param = 'psql';
    method _build__connection_psql {

        # process my passed options for psql attributes
        my ( $host, $port, $dbname, $username ) =
          map { $self->$_ }
          map { join q{_}, $_, $param }
          qw/ host port dbname username /;
        my $pass;
        my $vdb = CalVAD::HPMS::Geocoder::Schema->connect(
            "dbi:Pg:dbname=$dbname;host=$host;port=$port",
            $username, $pass, { on_connect_do =>
                        [ 'SET search_path TO public' ], ## no hpms schema now
                    },
        );
        return $vdb;
    }
    with 'DB::Connection' => {
        'name'                  => 'psql',
        'connection_type'       => 'CalVAD::HPMS::Geocoder::Schema',
        'connection_delegation' => qr/^(.*)/sxm,
    };

    has 'trigram' => (is => 'rw', isa => 'Bool', 'default'=>0);
    has 'county' => (is => 'rw', isa => 'Bool', 'default'=>0);

    my $km_to_miles = 0.621371192;

    sub query_dump {
      my ($dump,@colvals) = @_;
      for my $i (1 .. scalar @colvals){
        my $idx = $i-1;
        $dump =~ s/\$$i/'$colvals[$idx]'/;
      }
      carp "query is: $dump";
      return;
    }

    my $_get_roadway_section_trigram_county_osm = sub{
      my ($storage, $dbh, $nearcl, @colvals ) = @_;
      my $geoquery =q{select st_asewkt(st_transform(geom,4326)),len  FROM find_road_osm_trigram( $1,$2,$3,$4 )};
      my @row;
      carp 'calling osm county version';
      if($nearcl){
          $geoquery =q{select st_asewkt(st_transform(geom,4326)),len  FROM find_road_cl_osm_cnty_trigram( $1,$2,$3 )};
          query_dump($geoquery,@colvals[0,1,3]);
          @row = $dbh->selectrow_array($geoquery,undef, @colvals[0,1,3]);
      }else{
        query_dump($geoquery,@colvals);
        @row = $dbh->selectrow_array($geoquery,undef, @colvals);
      }
      return @row;
    };

}
1;
