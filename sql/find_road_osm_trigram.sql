CREATE OR REPLACE FUNCTION find_road_osm_trigram(IN roadway text, IN in_county text)
RETURNS TABLE(osm_id varchar, name varchar, cell_id varchar, other_tags hstore) AS
$BODY$
DECLARE
    var_sql text := '';
    ret record;
    in_statefp varchar(2) ;

BEGIN
    IF COALESCE(roadway,'') = '' THEN
        -- not enough to give a result just return
        RAISE NOTICE 'need a street to do this';
        return next;
    END IF;
    IF COALESCE(in_county,'') = '' THEN
        -- not enough to give a result just return
        RAISE NOTICE 'need a county to do this';
        return next;
    END IF;
var_sql := '
WITH
    cnty as (select name,ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03
             where conum= cast($2 as numeric)
             group by name),
    sim_ranking as (select r.*, similarity(r.name,$1) as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(r.name,$1) > 0.1
           order by score desc),
    max_sim as (select max(score) as max_sim from sim_ranking),
    s1_segments as (select sim_ranking.* from sim_ranking, max_sim where score = max_sim)
    select osm_id, name, cell_id, other_tags
           from s1_segments s1
           join carbgrid.state4k on (wkb_geometry && geom4326)
';
RETURN QUERY  EXECUTE var_sql  USING roadway,in_county;
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT;
