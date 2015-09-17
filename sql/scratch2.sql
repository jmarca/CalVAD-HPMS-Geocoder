-- goal here is to try to generate better road segments
-- use similar names to produce joined up roads
-- not sure how yet
--
-- basic idea is to do all to all distance, and pick off road segments
-- that touch at a node.  should be able to do this using nodes and ways, with nodes that share ways.  Not sure what is what.

-- SPRUCE ROAD                               | URL @ PALM ST to URL @ MYER RD                      |                 3.49

WITH
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    sim_ranking as (
           select ogc_fid,name,other_tags,wkb_geometry, similarity(r.name,'SPRUCE ROAD') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(r.name,'SPRUCE ROAD') > 0.1
           UNION
           select ogc_fid,r1.other_tags -> 'name_1' as name, other_tags,wkb_geometry, similarity(r1.other_tags -> 'name_1','SPRUCE ROAD') as score
           from lines r1
           join cnty on (r1.wkb_geometry && cnty.geom)
           where similarity(r1.other_tags -> 'name_1','SPRUCE ROAD') > 0.1
           order by score desc),
    -- sim_ranking2 as (
    --        select fullname as name,r.geom as wkb_geometry, similarity(r.fullname,'SPRUCE ROAD') as score
    --        from roads_jun_2015 r
    --        join cnty on (r.geom && cnty.geom)
    --        where similarity(r.fullname,'SPRUCE ROAD') > 0.1
    --        order by score desc),
    max_sim as (select max(score) as max_sim from sim_ranking),
    s1_segments as (select s.* from sim_ranking s, max_sim where score > max_sim - 0.1),
---    s1_g as (select name, ST_MakeLine(ST_LineMerge(wkb_geometry)) as geom from s1_segments group by name),
---
--- first intersection
---


-- okay, different strategy.  Use OSM data to sift out the network.
-- Each way has nodes in it that link to other ways.  With that
-- information I can build a network, then find the segments and path
-- from the start point to the end point along the intended road.

-- the question is how to build a network in an efficient manner, and
-- how to locate the start and end intersection.

-- I'm thinking that the best approach is probably to build a
-- county-wide network as a first step, then use that to geocode
-- everything.

-- so are there any existing libraries that will build a network for
-- me from OSM data, or should I write my own?

-- hmm.  maybe not perfect, but pgRouting seems to do this.  Makes a network of the entire map.

-- Still need to find the start and end nodes.

-- But once I find those, I can probably do the job without needing the routing engine?

-- code to find an intersection of two ways with a known name.


-- SPRUCE ROAD                               | URL @ PALM ST to URL @ MYER RD                      |                 3.49

-- ah, but use osmosis-generated db, because in the ogr2ogr one, no way-tag

WITH
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key from ways
        join cnty on (ways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values where key ~* 'name'
    ),
    road_ranking as (
           select osm_id, name, similarity(name,'SPRUCE ROAD') as score
           from name_values
    ),
    road_ranking_max as (
        select osm_id,max(score) as score
        from road_ranking
        where score > 0.1
        group by osm_id
    ),
    from_ranking as (
           select osm_id, name, similarity(name,'PALM ST') as score
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
           select osm_id, name, similarity(name,'MYER RD') as score
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
        select distinct w.nodes as road_nodes,w2.nodes as crossing_nodes,m.osm_id as road_id, m.score as road_score,f.score as crossing_score
        from road_ranking_max m
        join ways w on (m.osm_id=w.id)
        join ways w2 on (w.nodes && w2.nodes)
        join from_ranking_max f on (w2.id = f.osm_id)
        where m.osm_id != f.osm_id
        order by road_score desc,crossing_score desc
        limit 1
    ),
    to_ways as (
        select distinct w.nodes as road_nodes,w2.nodes as crossing_nodes,m.osm_id as road_id, m.score as road_score,t.score as crossing_score
        from road_ranking_max m
        join ways w on (m.osm_id=w.id)
        join ways w2 on (w.nodes && w2.nodes)
        join to_ranking_max t on (w2.id = t.osm_id)
        where m.osm_id != t.osm_id
        order by road_score desc, crossing_score desc
        limit 1
    )
select f.road_id as from_way, t.road_id as to_way, f.road_nodes as from_nodes,t.road_nodes as to_nodes
from from_ways f, to_ways t;


--  from_way |  to_way  |                                         from_nodes                                          |                        to_nodes
------------+----------+---------------------------------------------------------------------------------------------+---------------------------------------------------------
-- 10676953 | 10676898 | {94572309,94572727,94572728,94572730,94572731,94562883,94572732,94572733,94554912,94555369} | {94572305,94562928,94572306,94572307,94572308,94572309}
-- (1 row)


start condition: collected_nodes = to_nodes

stop condition: from_nodes && collected_nodes

iteration: add best candidate way to collected_nodes

new_way1, new_way2, which is closer to "from_way"

add closer way to collected_nodes
use closer_way as new pivot thing?


if from_nodes[0] = to_nodes[0] or to_nodes[-1]


WITH recursive
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key from ways
        join cnty on (ways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values where key ~* 'name'
    ),
    road_ranking as (
           select osm_id, name, similarity(name,'SPRUCE ROAD') as score
           from name_values
    ),
    road_max as (
        select max(score) as max_score
        from road_ranking
    ),
    road_ranking_max as (
        select osm_id,score
        from road_ranking,road_max
        where score > max_score - 0.3 -- just to get a bunch
    ),
    link_nodes(id, nodes, distance, depth, path, cycle) AS (
        SELECT g.id, g.link, g.data, 1,
          ARRAY[g.id],
          false
        FROM graph g
      UNION ALL
        SELECT g.id, g.link, g.data, sg.depth + 1,
          path || g.id,
          g.id = ANY(path)
        FROM graph g, search_graph sg
        WHERE g.id = sg.link AND NOT cycle
)
SELECT * FROM search_graph;

with recursive search_path()


with recursive
   wayslist

with -- recursive
   end_point as (
      select * from ways where id = 10676898
   ),
   nodeslist as (
      select id,ARRAY[nodes[1],nodes[array_length(nodes,1)]] as nodes
      from ways
      where id = 10676953
   ),
   next_way as (
      select nl.id,end_point.id,
             ARRAY[nl.id,b.id] as aorb,
             ARRAY[nl.nodes[1],b.nodes[array_length(b.nodes,1)]] as nodes,
             ST_DISTANCE(end_point.linestring,b.linestring) as dist
      from nodeslist nl
      join ways b on (nl.nodes[2] = b.nodes[1] and b.id != nl.id)
      join end_point on (1=1)
     union
      select nl.id,end_point.id,
             ARRAY[a.id,nl.id] as aorb,
             ARRAY[a.nodes[1],nl.nodes[2]] as nodes,
             ST_DISTANCE(end_point.linestring,a.linestring) as dist
      from nodeslist nl
      join ways a on (nl.nodes[1] = a.nodes[array_length(a.nodes,1)] and a.id != nl.id)
      join end_point on (1=1)

   )
select distinct * from next_way order by dist ;

-- okay, that is working.  now merge with the name-based queries above, then recurse it

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


with -- recursive
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key from ways
        join cnty on (ways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values where key ~* 'name'
    ),
    road_ranking as (
           select osm_id, name, similarity(name,'SPRUCE ROAD') as score
           from name_values
    ),
    road_max as (
        select max(score) as max_score
        from road_ranking
    ),
    road_ranking_max as (
        select osm_id,score
        from road_ranking,road_max
        where score > max_score - 0.3 -- just to get a bunch
    ),
    -- end point
   end_point as (
      select * from ways where id = 10676898
   ),
    -- starting point
   start_point  (id, path, nodes, distance, cyclic) as (
      select id, ARRAY[id] as path, ARRAY[nodes[1],nodes[array_length(nodes,1)]] as nodes, 0 as distance, 1=0 as cyclic from ways where id = 10676953
   ),
   way_path (id, path, nodes, distance, cyclic) as (
      select unnest(ARRAY[b.id,a.id]),
             unnest_2d_1d(
                ARRAY[
                   array_append(nl.path,b.id),
                   array_prepend(a.id,nl.path)
                ]) as path,
             unnest_2d_1d(
                ARRAY[
                   ARRAY[nl.nodes[1],b.nodes[array_length(b.nodes,1)]],
                   ARRAY[a.nodes[1],nl.nodes[2]]
                ]) as nodes,
             unnest(
                ARRAY[ST_DISTANCE(end_point.linestring,b.linestring),
                      ST_DISTANCE(end_point.linestring,a.linestring)
                ]) as distance,
             unnest(ARRAY[b.id = ANY(path),a.id = ANY(path)]) as cyclic
      from start_point nl
      join ways b on (nl.nodes[2] = b.nodes[1] and b.id != nl.id)
      join ways a on (nl.nodes[1] = a.nodes[array_length(a.nodes,1)] and a.id != nl.id)
      join end_point on (1=1)
      order by distance limit 1
   )
select distinct * from way_path order by distance limit 1 ;


--- okay, now try to make it with recursive

WITH RECURSIVE
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key from ways
        join cnty on (ways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values where key ~* 'name'
    ),
    road_ranking as (
           select osm_id, name, similarity(name,'SPRUCE ROAD') as score
           from name_values
    ),
    road_max as (
        select max(score) as max_score
        from road_ranking
    ),
    road_ranking_max as (
        select osm_id,score
        from road_ranking,road_max
        where score > max_score - 0.3 -- just to get a bunch
    ),
    -- end point
   end_point as (
      select * from ways where id = 10676898
   ),
    -- starting point
   start_point  (id, path, nodes, distance, cyclic) as (
      select * from ways where id = 10676953
   ),
   way_path (id, path, nodes, distance, cyclic) as (
      select id,
             ARRAY[id] as path,
             ARRAY[nodes[1],nodes[array_length(nodes,1)]] as nodes,
             0 as distance,
             1=0 as cyclic
      from start_point

    UNION ALL
      select unnest(ARRAY[b.id,a.id]),
             unnest_2d_1d(
                ARRAY[
                   array_append(wp.path,b.id),
                   array_prepend(a.id,wp.path)
                ]) as path,
             unnest_2d_1d(
                ARRAY[
                   ARRAY[wp.nodes[1],b.nodes[array_length(b.nodes,1)]],
                   ARRAY[a.nodes[1],wp.nodes[2]]
                ]) as nodes,
             unnest(
                ARRAY[ST_DISTANCE(end_point.linestring,b.linestring),
                      ST_DISTANCE(end_point.linestring,a.linestring)
                ]) as distance,
             unnest(ARRAY[b.id = ANY(path),a.id = ANY(path)]) as cyclic
      from way_path wp
      join ways b on (wp.nodes[2] = b.nodes[1] and b.id != wp.id)
      join ways a on (wp.nodes[1] = a.nodes[array_length(a.nodes,1)] and a.id != wp.id)
      join end_point on (1=1)
      where NOT cyclic
      order by distance limit 1
   )
select distinct * from way_path ;

-- fails because order by in a recursive query is not implemented.

-- okay, how about a case statement?


WITH RECURSIVE
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key from ways
        join cnty on (ways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values where key ~* 'name'
    ),
    road_ranking as (
           select osm_id, name, similarity(name,'SPRUCE ROAD') as score
           from name_values
    ),
    road_max as (
        select max(score) as max_score
        from road_ranking
    ),
    road_ranking_max as (
        select ways.*
        from road_ranking
        join ways on (osm_id=id)
        join road_max on (1=1)
        where score > max_score - 0.3 -- just to get a bunch
        order by score desc
    ),
   end_point as (
      select * from ways where id = 10676898
   ),
    -- starting point
   start_point  as (
      select * from ways where id = 10676953
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
   )
select distinct * from way_path ;


-- okay, let's go dancing

WITH RECURSIVE
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key from ways
        join cnty on (ways.bbox && cnty.geom)
    ),
    name_values as (
        select osm_id,name from tag_values where key ~* 'name'
    ),
    road_ranking as (
           select osm_id, name, similarity(name,'SPRUCE ROAD') as score
           from name_values
    ),
    road_ranking_no_repeats as (
        select osm_id, max(score) as score
        from road_ranking
        where score > 0.1
        group by osm_id
    ),
    road_ranking_max as (
        select distinct ways.*, score
        from road_ranking_no_repeats
        join ways on (osm_id=id)
        --  join road_max on (1=1)
        where score > 0.1
    ),
    from_ranking as (
           select osm_id, name, similarity(name,'PALM ST') as score
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
           select osm_id, name, similarity(name,'MYER RD') as score
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
        select distinct m.nodes as road_nodes,w2.nodes as crossing_nodes,m.id as road_id, m.score as road_score,f.score as crossing_score
        from road_ranking_max m
        join ways w2 on (m.nodes && w2.nodes)
        join from_ranking_max f on (w2.id = f.osm_id)
        where m.id != f.osm_id
        order by road_score desc,crossing_score desc
        limit 1
    ),
    to_ways as (
        select distinct m.nodes as road_nodes,w2.nodes as crossing_nodes,m.id as road_id, m.score as road_score,t.score as crossing_score
        from road_ranking_max m
        join ways w2 on (m.nodes && w2.nodes)
        join to_ranking_max t on (w2.id = t.osm_id)
        where m.id != t.osm_id
        order by road_score desc, crossing_score desc
        limit 1
    ),
    -- slightly redundant here
   end_point as (
      select * from ways join to_ways on (road_id=id)
   ),
   start_point  as (
      select * from ways join from_ways on (road_id=id)
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
   (st_length(st_transform(geom,32611)) * 0.000621371192) as len,
   st_asewkt(st_linemerge(geom))
   from geom_path;

-- huzzah!
