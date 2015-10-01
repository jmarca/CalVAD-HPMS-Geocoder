CREATE OR REPLACE FUNCTION from_to_sets(IN roadname text, IN way_id bigint)
returns bigint
as
$BODY$
DECLARE
    var_sql text := '';
    name_pattern text := 'name';
    ret record;
    in_statefp varchar(2) ;
    results RECORD;
BEGIN
    IF COALESCE(roadway,'') = '' THEN
        -- not enough to give a result just return
        RAISE NOTICE 'need a street to do this';
        return results;
    END IF;
    IF COALESCE(from_road,to_road,'') = '' THEN
        -- not enough to give a result just return
        RAISE NOTICE 'need a from and/or to road to do this';
        return results;
    END IF;
    IF COALESCE(in_county,'') = '' THEN
        -- not enough to give a result just return
        RAISE NOTICE 'need a county to do this';
        return results;
    END IF;
var_sql := '
WITH
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = $2 group by c.name),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key from ways
        join cnty on (ways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values where key ~* '
 || quote_literal(name_pattern)
 || '
    ),
    road_ranking as (
           select osm_id, name, similarity(name,$1) as score
           from name_values
    ),
    road_ranking_no_repeats as (
        select osm_id, max(score) as score
        from road_ranking
        where score > 0.1
        group by osm_id
    ),
    named_road_ranking_no_repeats as (
        select (array_agg(v.name))[1] as name, r.osm_id, r.score
        from road_ranking_no_repeats r
        join road_ranking v on (r.osm_id=v.osm_id and r.score=v.score)
        group by r.osm_id,r.score
    ),
    road_ranking_max as (
        select distinct ways.*, r.score, r.name
        from named_road_ranking_no_repeats r
        join ways on (osm_id=id)
    ),
    from_ranking as (
           select osm_id, name, similarity(name,$3) as score
           from name_values
    ),
    from_max as (
        select max(score) as max_from_score
        from from_ranking
    ),
    from_ranking_max as (
        select osm_id,max(score) as score
        from from_ranking, from_max
        where score > max_from_score - 0.1
        group by osm_id
    ),
    to_ranking as (
           select osm_id, name, similarity(name,$4) as score
           from name_values
    ),
    to_max as (
        select max(score) as max_to_score
        from to_ranking
    ),
    to_ranking_max as (
        select osm_id,max(score) as score
        from to_ranking, to_max
        where score > max_to_score - 0.1
        group by osm_id
    ),
    from_ways as (
        select distinct m.name, m.nodes as road_nodes,w2.nodes as crossing_nodes,m.id as road_id, m.score as road_score,f.score as crossing_score
        from road_ranking_max m
        join ways w2 on (m.nodes && w2.nodes)
        join from_ranking_max f on (w2.id = f.osm_id)
        where m.id != f.osm_id
        order by road_score desc,crossing_score desc
        --        limit 1
    ),
    to_ways as (
        select distinct m.name, m.nodes as road_nodes,w2.nodes as crossing_nodes,m.id as road_id, m.score as road_score,t.score as crossing_score
        from road_ranking_max m
        join ways w2 on (m.nodes && w2.nodes)
        join to_ranking_max t on (w2.id = t.osm_id)
        where m.id != t.osm_id
        order by road_score desc, crossing_score desc
        -- limit 1
    )
select
   1 as ft, name,road_nodes,crossing_nodes,road_score,crossing_score from from_ways
   union
select
   2 as ft, name,road_nodes,crossing_nodes,road_score,crossing_score from to_ways
';
  EXECUTE var_sql into results USING roadway,in_county,from_road,to_road;
  RETURN results;
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT;
