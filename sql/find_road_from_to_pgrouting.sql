
-- very useful
CREATE OR REPLACE FUNCTION unnest_2d_1d(anyarray)
  RETURNS SETOF anyarray AS
$func$
SELECT array_agg($1[d1][d2])
FROM   generate_subscripts($1,1) d1
    ,  generate_subscripts($1,2) d2
GROUP  BY d1
ORDER  BY d1
$func$
LANGUAGE sql IMMUTABLE;


DROP TYPE IF EXISTS streetlength2 CASCADE;
CREATE TYPE streetlength2 AS (
       from_road_name text,
       to_road_name text,
       from_crossing_name text,
       to_crossing_name text,
       len double precision,
       geom  geometry
);



CREATE OR REPLACE FUNCTION find_road_from_to_osm_pgrouting(IN roadway text, IN from_road text, IN to_road text, IN in_county text)
RETURNS SETOF streetlength2
AS
$BODY$
DECLARE
    var_sql text := '';
    var_backup_sql text := '';
    dijk_sql text := '';
    var_no_shape text := '';
    name_pattern text := 'name';
    type_pattern text := '_type';
    direction_pattern text := '_direction';
    highway_tag text := 'highway';
    ret record;
    in_statefp varchar(2) ;
    results streetlength2;
BEGIN
    IF COALESCE(roadway,'') = '' THEN
        -- not enough to give a result just return
        RAISE NOTICE 'need a street to do this';
        RETURN;
    END IF;
    IF COALESCE(from_road,to_road,'') = '' THEN
        -- not enough to give a result just return
        RAISE NOTICE 'need a from and/or to road to do this';
        RETURN;
    END IF;
    IF COALESCE(in_county,'') = '' THEN
        -- not enough to give a result just return
        RAISE NOTICE 'need a county to do this';
        RETURN;
    END IF;
    dijk_sql := '
with cnty as (
    select ST_ENVELOPE(ST_Union(geom4326)) as geom
    from public.carb_counties_aligned_03 c
    join counties_fips cf  on (cf.name ~* c.name and cf.fips = '
    || quote_literal(in_county)
    ||'::varchar)
    group by c.name)
select gid as id, source_osm as source,
       target_osm as target, cost
from routing.ways
join cnty on (ways.the_geom && cnty.geom)
';
var_no_shape := '
WITH
    roadwayname (n) as (
       select $1::text
    ),
    fromname (n) as (
       select $3::text
    ),
    toname (n) as (
       select $4::text
    ),
    fipscode (c) as (
       select $2::varchar
    ),
    cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             join fipscode on (fipscode.c = cf.fips)
             group by c.name),
    cnty_names as (
        select distinct id,name,ways.nodes,ways.bbox,ways.linestring
        from osm.way_name_view
        join osm.ways USING (id)
        join cnty on (ways.bbox && cnty.geom)
    ),
    road_ranking as (
           select id, name, nodes, similarity(name,fm.n) as score,linestring
           from cnty_names
           join roadwayname fm on (1=1)
    ),
    road_max as (
        select max(score) as max_score
        from road_ranking
    ),
    road_max_id as (
        select id,max(score) as score
        from road_ranking, road_max
        where score > max_score - 0.5 -- generous here
        group by id
    ),
    road_ranking_max as (
        select id,name,unnest(nodes) as node,score
        from road_max_id
        join road_ranking USING (id,score)
    ),
    from_ranking as (
           select id, name, nodes, similarity(name,fm.n) as score
           from cnty_names
           join fromname fm on (1=1)
    ),
    from_max as (
        select max(score) as max_score
        from from_ranking
    ),
    from_max_id as (
        select id,max(score) as score
        from from_ranking, from_max
        where score > max_score - 0.1
        group by id
    ),
    from_ranking_max as (
        select id,name,unnest(nodes) as node,score
        from from_max_id
        join from_ranking USING (id,score)
    ),
    to_ranking as (
           select id, name, nodes, similarity(name,tm.n) as score
           from cnty_names
           join toname tm on (1=1)
    ),
    to_max as (
        select max(score) as max_score
        from to_ranking
    ),
    to_max_id as (
        select id,max(score) as score
        from to_ranking, to_max
        where score > max_score - 0.1
        group by id
    ),
    to_ranking_max as (
        select id,name,unnest(nodes) as node,score
        from to_max_id
        join to_ranking USING (id,score)
    ),
    end_points_all as (
        select 1 as which, f.id as c_id,r1.id,f.name as c_name,r1.name,f.node,f.score as c_score,r1.score as score
        from from_ranking_max f
        join road_ranking_max r1 on (r1.node=f.node and r1.name != f.name)
        union
        select 2 as which, t.id as c_id,r2.id,t.name as c_name,r2.name,t.node,t.score as c_score,r2.score as score
        from to_ranking_max t
        join road_ranking_max r2 on (r2.node=t.node and r2.name != t.name)
        order by score desc
    ),
    unique_ends as (
        select which,node,max(score) as score,max(c_score) as c_score
        from end_points_all
        group by which,node
    ),
    best_match_end as (
        select which from unique_ends
        order by score desc,c_score desc
        limit 1
    ),
    start_nodes as (
        select u.which,node,max(score) as score,max(c_score) as c_score
        from unique_ends u
        join best_match_end b on (b.which=u.which)
        group by u.which,node
    ),
    start_nodes_2 as (
        select sn.which,sn.node,sn.score,sn.c_score,(array_agg(ep.id))[1] as id,(array_agg(ep.name))[1] as name,(array_agg(ep.c_name))[1] as c_name
        from start_nodes sn
        join end_points_all ep USING (which,node,score,c_score)
        group by sn.which,sn.node,sn.score,sn.c_score
        order by sn.score desc,sn.c_score desc
        limit 1
    ),
    end_nodes as (
        select u.which,node,max(score) as score,max(c_score) as c_score
        from unique_ends u
        join best_match_end b on (b.which!=u.which)
        group by u.which,node
    ),
    end_nodes_2 as (
        select sn.which,sn.node,sn.score,sn.c_score,(array_agg(ep.id))[1] as id,(array_agg(ep.name))[1] as name,(array_agg(ep.c_name))[1] as c_name
        from end_nodes sn
        join end_points_all ep USING (which,node,score,c_score)
        group by sn.which,sn.node,sn.score,sn.c_score
        order by sn.score desc,sn.c_score desc
        limit 1
    ),
    pairs as (
        select f.node as f_node,t.node as t_node,f.id as from_id,t.id as to_id,
        f.name as from_road_name,f.c_name as from_crossing_name,
        t.name as to_road_name,t.c_name as to_crossing_name
        from
        end_nodes_2 t cross join start_nodes_2 f
    )';
var_sql := var_no_shape
|| ',
    paths as (
        select p.*,  max(dijk.agg_cost) as cost,
        st_linemerge( st_collect(w.the_geom) ) as geom
        from
        pairs p
        join
        pgr_dijkstra('
|| quote_literal(dijk_sql)
|| '    ,f_node, t_node)  dijk on (1=1)
        join routing.ways w on (dijk.edge = w.gid)
        group by f_node,t_node,from_id,to_id,from_road_name,from_crossing_name,to_road_name,to_crossing_name
        )
   select
       from_road_name, to_road_name, from_crossing_name, to_crossing_name,
       (st_length(st_transform(geom,32611)) * 0.000621371192) as len,
       geom
   from pairs
   left outer join paths USING(from_road_name, to_road_name, from_crossing_name, to_crossing_name)
   order by len
';
var_backup_sql := var_no_shape
|| '
   select
       from_road_name, to_road_name, from_crossing_name, to_crossing_name,
       null::double precision as len,
       null::GEOMETRY as geom
   from pairs
';
  RETURN QUERY EXECUTE var_sql USING roadway,in_county,from_road,to_road;

    -- Since execution is not finished, we can check whether rows were returned
    -- and return something else??
    IF NOT FOUND THEN
    --        RETURN QUERY EXECUTE var_backup_sql USING roadway,in_county,from_road,to_road;
        RAISE EXCEPTION 'No roadways matching % from % to %.', roadway,from_road,to_road;
    END IF;

  RETURN;
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE STRICT;
