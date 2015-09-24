CREATE OR REPLACE FUNCTION from_to_sets(IN roadway text, IN from_road text, IN to_road text, IN in_county text)
returns RECORD
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



--- 'CHURCH RD',  'ARMSTRONG AVE','SIERRA AVE' , '06107'
--- 'AVENUE 116', 'ROAD 264', 'DIAGONAL 254'
--- 'SUCCESS DR', 'RD 248', 'SPRINGVILLE AVE', '06107'

WITH
    roadwayname (n) as (
       select 'AVENUE 116'::text
    ),
    fromname (n) as (
       select 'ROAD 264'::text
    ),
    toname (n) as (
       select 'DIAGONAL 254'::text
    ),
    fipscode (c) as (
       select '06107'::varchar
    ),
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             join fipscode on (fipscode.c = cf.fips)
             group by c.name),
    roadways as (
        select *
        from ways
        where tags ? 'highway'
    ),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key
        from roadways  join cnty on (roadways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values
        where key ~* 'name' and
              key !~* '_base' and
              key !~* '_type'
-- || quote_literal(name_pattern)
-- || '
    ),
    road_ranking as (
           select osm_id, name, similarity(name,rn.n) as score
           from name_values,roadwayname rn
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
        select distinct roadways.*, r.score, r.name
        from named_road_ranking_no_repeats r
        join roadways on (osm_id=id)
    ),
    from_ranking as (
           select osm_id, name, similarity(name,fm.n) as score
           from name_values,fromname fm
    ),
    from_max as (
        select max(score) as max_from_score
        from from_ranking
    ),
    from_ranking_max as (
        select osm_id,name,score
        from from_ranking, from_max
        where score > max_from_score - 0.1
    ),
    to_ranking as (
           select osm_id, name, similarity(name,tm.n) as score
           from name_values,toname tm
    ),
    to_max as (
        select max(score) as max_to_score
        from to_ranking
    ),
    to_ranking_max as (
        select osm_id,name,score
        from to_ranking, to_max
        where score > max_to_score - 0.1
    ),
    end_points_all as (
        select 1 as which, osm_id,name,score from from_ranking_max
        union
        select 2 as which, osm_id,name,score from to_ranking_max
        order by score desc
    ),
    crossing_candidates as (
        select distinct which, m.name, m.nodes as road_nodes,w2.nodes as crossing_nodes,
                        m.id as road_id, m.score as road_score,
                        f.osm_id as crossing_id,f.score as crossing_score,f.name as crossing_name
        from road_ranking_max m
        join roadways w2 on (m.nodes && w2.nodes)
        join end_points_all f on (w2.id = f.osm_id)
        where m.id != f.osm_id
        order by road_score desc,crossing_score desc
    ),
    start_point as (
        select which,name,crossing_name,roadways.*
        from crossing_candidates
        join roadways on (road_id=roadways.id)
        order by road_score desc,crossing_score desc
        limit 1
    ),
    end_point as (
        select c.which,c.name,c.crossing_name,roadways.*
        from crossing_candidates c
        join start_point s on (c.which != s.which)
        join roadways on (c.road_id=roadways.id)
        order by road_score desc,crossing_score desc
        limit 1
    )
select which,name,crossing_name,id from start_point
union
select which,name,crossing_name,id from end_point
;

--  better.  resistant to ordering issues at least.

-- try the full query


WITH RECURSIVE
    roadwayname (n) as (
       select 'AVENUE 116'::text
    ),
    fromname (n) as (
       select 'ROAD 264'::text
    ),
    toname (n) as (
       select 'DIAGONAL 254'::text
    ),
    fipscode (c) as (
       select '06107'::varchar
    ),
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             join fipscode on (fipscode.c = cf.fips)
             group by c.name),
    roadways as (
        select *
        from ways
        where tags ? 'highway'
    ),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key
        from roadways  join cnty on (roadways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values
        where key ~* 'name' and
              key !~* '_direction' and
              key !~* '_type'
-- || quote_literal(name_pattern)
-- || '
    ),
    road_ranking as (
           select osm_id, name, similarity(name,rn.n) as score
           from name_values,roadwayname rn
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
        select distinct roadways.*, r.score, r.name
        from named_road_ranking_no_repeats r
        join roadways on (osm_id=id)
    ),
    from_ranking as (
           select osm_id, name, similarity(name,fm.n) as score
           from name_values,fromname fm
    ),
    from_max as (
        select max(score) as max_from_score
        from from_ranking
    ),
    from_ranking_max as (
        select osm_id,name,score
        from from_ranking, from_max
        where score > max_from_score - 0.1
    ),
    to_ranking as (
           select osm_id, name, similarity(name,tm.n) as score
           from name_values,toname tm
    ),
    to_max as (
        select max(score) as max_to_score
        from to_ranking
    ),
    to_ranking_max as (
        select osm_id,name,score
        from to_ranking, to_max
        where score > max_to_score - 0.1
    ),
    end_points_all as (
        select 1 as which, osm_id,name,score from from_ranking_max
        union
        select 2 as which, osm_id,name,score from to_ranking_max
        order by score desc
    ),
    crossing_candidates as (
        select distinct which, m.name, m.nodes as road_nodes,w2.nodes as crossing_nodes,
                        m.id as road_id, m.score as road_score,
                        f.osm_id as crossing_id,f.score as crossing_score,f.name as crossing_name
        from road_ranking_max m
        join roadways w2 on (m.nodes && w2.nodes)
        join end_points_all f on (w2.id = f.osm_id)
        where m.id != f.osm_id
        order by road_score desc,crossing_score desc
    ),
    start_point as (
        select which,name,crossing_name,roadways.*
        from crossing_candidates
        join roadways on (road_id=roadways.id)
        order by road_score desc,crossing_score desc
        limit 1
    ),
    end_point as (
        select c.which,c.name,c.crossing_name,roadways.*
        from crossing_candidates c
        join start_point s on (c.which != s.which)
        join roadways on (c.road_id=roadways.id)
        order by road_score desc,crossing_score desc
        limit 1
    ),
   way_path (id, path, nodes, distance, depth, cyclic, theend)
      as (
      select sp.id,
             ARRAY[sp.id] as path,
             ARRAY[sp.nodes[1],sp.nodes[array_length(sp.nodes,1)]] as nodes,
             ARRAY[LEAST(ST_DISTANCE(end_point.linestring,forward.linestring),100), -- forward is 1, backward is 2
                   LEAST(ST_DISTANCE(end_point.linestring,backward.linestring),100)]-- and null => 100 (impossibly large)
                                                                                    -- only if DISTANCE() calc is null
                   as distance,
             1 as depth,
             1=0 as cyclic,
             sp.id=end_point.id as theend
      from start_point sp
      left outer join road_ranking_max forward on (sp.nodes[array_length(sp.nodes,1)] = forward.nodes[1] and forward.id != sp.id)
      left outer join road_ranking_max backward on (sp.nodes[1] = backward.nodes[array_length(backward.nodes,1)] and backward.id != sp.id)
      join end_point on (1=1)
     UNION ALL
      select CASE WHEN wp.distance[1] < wp.distance[2]
                  -- going forward
             THEN
                  b.id
             ELSE
                  a.id
             END,
             CASE WHEN wp.distance[1] < wp.distance[2]
                  -- going forward
             THEN
                   array_append(wp.path,b.id)
             ELSE
                   array_prepend(a.id,wp.path)
             END,
             CASE WHEN wp.distance[1] < wp.distance[2]
                  -- going forward
             THEN
                   ARRAY[wp.nodes[1],b.nodes[array_length(b.nodes,1)]]
             ELSE
                   ARRAY[a.nodes[1],wp.nodes[2]]
             END,
             CASE WHEN wp.distance[1] < wp.distance[2]
                  -- going forward.  Don't bother computing here
             THEN
                  ARRAY[0,1]
             ELSE
                  ARRAY[1,0]
             END,
             wp.depth + 1,
             CASE WHEN wp.distance[1] < wp.distance[2]
                  -- going forward
             THEN
                  (b.id = ANY(array_prepend(end_point.id,path)))
             ELSE
                  (a.id = ANY(array_prepend(end_point.id,path)))
             END,
             CASE WHEN wp.distance[1] < wp.distance[2]
                  -- going forward
             THEN
                  b.id=end_point.id
             ELSE
                  a.id=end_point.id
             END
      from way_path wp
      left outer join road_ranking_max b on (wp.nodes[2] = b.nodes[1] and b.id != wp.id)
      left outer join road_ranking_max a on (wp.nodes[1] = a.nodes[array_length(a.nodes,1)] and a.id != wp.id)
      join end_point on (1=1)
       where NOT cyclic -- and depth < 3
   ),
   full_path as (
       select path from way_path order by depth desc limit 1
   ),
   break_out_segs as (
       select unnest(path) as id from full_path
   ),
   get_geometries as (
       select (st_dump(linestring)).geom as geom from road_ranking_max a join break_out_segs b on (b.id = a.id)
   ),
   geom_path as (
       select st_collect(geom) as geom from get_geometries
   )
select
   s.name,
   s.crossing_name as from_name,
   e.crossing_name as to_name,
   st_asewkt(st_linemerge(geom)),
   (st_length(st_transform(geom,32611)) * 0.000621371192) as len
   from geom_path,start_point s,end_point e
   ;


CREATE TABLE hpms.hpms_match_details (
    hpms_id integer NOT NULL,
    direction text,
    intended_name varchar (256),
    intended_from varchar (256),
    intended_to   varchar (256),
    matched_name varchar (256),
    matched_from varchar (256),
    matched_to   varchar (256),
    primary key (hpms_id,direction)
);
ALTER TABLE ONLY hpms.hpms_match_details
    ADD CONSTRAINT hpms_match_details_hpms_id_fkey FOREIGN KEY (hpms_id) REFERENCES hpms.hpms(id) ON DELETE CASCADE;
