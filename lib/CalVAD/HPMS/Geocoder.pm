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
    # use CalVAD::HPMS::Cities;
    use CalVAD::HPMS::CensusAbbrev;

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

    my $abbrev_fixer = CalVAD::HPMS::CensusAbbrev->new();



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

    my $_get_roadway_section_trigram_osm = sub{
        my ($storage, $dbh, $nearcl, @colvals ) = @_;

        my $geoquery = q{select (res).name,(res).len,(res).geom  from (select find_road_from_to_osm_trigram($1,$2,$3,$4) as res) a };
        my @row;
        carp 'calling osm county version';
        if($nearcl){
            croak 'not yet handling county line conditions properly';
            # $geoquery =q{select st_asewkt(st_transform(geom,4326)),len  FROM find_road_cl_osm_cnty_trigram( $1,$2,$3 )};
            # query_dump($geoquery,@colvals[0,1,3]);
            # @row = $dbh->selectrow_array($geoquery,undef, @colvals[0,1,3]);
        }else{
            query_dump($geoquery,@colvals);
            @row = $dbh->selectrow_array($geoquery,undef, @colvals);
        }
        return @row;
    };

    # # will always use trigrams
    method get_roadway_section_osm (Str :$locality, Str :$road, Str :$from?, Str :$to?){

      my $nearcl;
      my $param0;
      my @param12;

      $param0=$abbrev_fixer->replace_census_abbrev_trigram($road);

      for my $crossing ($from,$to){
        # deal here with something like "CL @" which indicates city line or county line
        if($crossing =~ /^cl/i){
          $crossing =~ s/cl\s*@?//i;
          $nearcl = 1;
        }
        if($crossing =~ /county\s*line/i){
          $crossing = '';
          $nearcl = 1;
        }
        if($crossing =~ /\sco\sln/i){
          $crossing = '';
          $nearcl = 1;
        }
        # get rid of parenthetical remarks
        if($crossing =~ /\(.*\)/){
          $crossing =~ s/\(.*\)//;
        }

        if( $crossing =~ /\//){
          my @xing;
          # split on the slash, recombine
          my  @twostreets = split q{/},$crossing;
          for my $str (@twostreets){
            if(!$str){
              next;
            }
            my $result = $abbrev_fixer->replace_census_abbrev_trigram($str,1);
            if($result){
              push @xing,$result;
            }
          }
          if(scalar @xing){
              # just use the longer of the two
              my $longer = $xing[0];
              my $longest = length $longer ;
              for (@xing){
                  if(length $_ > $longest) {
                      $longer = $_;
                      $longest = length $longer ;
                  }
              }
              push @param12, $longer;


          }else{ # this doesn't really make sense, but whatever.  the idea is
                 # that if hpms give me unparseable garbage, then just get all
                 # of the road inside of the city limits
            $nearcl = 1;
          }
        }else{
            my $result = $abbrev_fixer->replace_census_abbrev_trigram($crossing,1);
            push @param12,$result;
        }
      }
      my @bindarray = ();
      my $geom;
        @bindarray = ($param0,$param12[0],$param12[1],$locality);

      if($self->county){
          # return $self->storage->dbh_do( $_get_roadway_section_trigram_county_osm,$nearcl, @bindarray);
          croak 'no county option at the moment';
      }else{
          return  $self->storage->dbh_do( $_get_roadway_section_trigram_osm,$nearcl, @bindarray);
      }
    }




}
1;
