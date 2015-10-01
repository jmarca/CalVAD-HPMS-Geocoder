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
        select f.osm_id as f_id,f.name as f_name,f.score as f_score,
        t.osm_id as t_id,t.name as t_name,t.score as t_score
        from from_ranking_max f
        cross join to_ranking_max t
        order by f_score desc,  t_score desc
    )

select seq,id1 as node, id2 as edge, cost
from
pgr_dijkstra('select osm_id as id,source_osm as source, target_osm as target, cost from routing.ways',
)


select seq,id1 as node, id2 as edge, cost
from
pgr_dijkstra('select osm_id as id,source_osm as source, target_osm as target, cost from routing.ways',
             6448,18928
)

select  pgr_dijkstra('select gid as id, source,  target, cost from routing.ways',    6448,2594);


select pgr_dijkstra('select osm_id as id,source_osm as source, target_osm as target, cost from routing.ways',
             242825711,10673962);


crs_small2=# select id,nodes[1],nodes[array_length(nodes,1)] from ways where id in (10673962,242825710,242825711);
    id     |  nodes   |  nodes
-----------+----------+----------
  10673962 | 94548856 | 94548866
 242825710 | 94548866 | 94063224
 242825711 | 94063224 | 94548889

select * from routing.osm_nodes where osm_id in (94548856,94548889);
 node_id |  osm_id  |      lon      |     lat     | numofuse |...
---------+----------+---------------+-------------+----------+-
   49771 | 94548856 | -118.98234200 | 35.93526200 |        2 |...
   49803 | 94548889 | -118.98242800 | 36.02955000 |        2 |...



select w.osm_id,w.source,w.target,n.node_id,n.osm_id from routing.ways w join routing.osm_nodes n on (w.source=n.node_id) where
w.osm_id in (10673962,242825710,242825711) order by w.osm_id,source;

  osm_id   | source | target | node_id |  osm_id
-----------+--------+--------+---------+----------
  10673962 |   1851 |  12202 |    1851 | 87436236
  10673962 |   1951 |   1851 |    1951 | 87442024
  10673962 |   5084 |  19048 |    5084 | 87542840
  10673962 |   6448 |  13020 |    6448 | 87586535
  10673962 |   9814 |  18215 |    9814 | 87910921
  10673962 |   9855 |  31045 |    9855 | 87912954
  10673962 |  12202 |   9814 |   12202 | 88261085
  10673962 |  13020 |  22530 |   13020 | 88275365
  10673962 |  18215 |   2594 |   18215 | 88406028
  10673962 |  19048 |   9855 |   19048 | 88550574
  10673962 |  22530 |   5084 |   22530 | 88748651
  10673962 |  31045 |   1951 |   31045 | 94027538
 242825710 |   2594 |  25106 |    2594 | 87472646
 242825710 |  25106 |  17366 |   25106 | 94003811
 242825711 |  13040 |  33264 |   13040 | 88275409
 242825711 |  17366 |  13040 |   17366 | 88395667
 242825711 |  32274 |  17422 |   32274 | 94031355
 242825711 |  33264 |  32274 |   33264 | 94034427
(18 rows)


select  pgr_dijkstra('select gid as id, source,  target, cost from routing.ways',6448, 17422);



  osm_id   | source | target | source_osm | target_osm | node_id |  osm_id
-----------+--------+--------+------------+------------+---------+----------
  10673962 |   1851 |  12202 |   94548862 |   94548863 |    1851 | 87436236
  10673962 |   1951 |   1851 |   94048571 |   94548862 |    1951 | 87442024
  10673962 |   5084 |  19048 |   94548858 |   94548859 |    5084 | 87542840
  10673962 |   6448 |  13020 |   94548856 |   94051541 |    6448 | 87586535
  10673962 |   9814 |  18215 |   94548864 |   94548865 |    9814 | 87910921
  10673962 |   9855 |  31045 |   94548860 |   94548861 |    9855 | 87912954
  10673962 |  12202 |   9814 |   94548863 |   94548864 |   12202 | 88261085
  10673962 |  13020 |  22530 |   94051541 |   94548857 |   13020 | 88275365
  10673962 |  18215 |   2594 |   94548865 |   94548866 |   18215 | 88406028
  10673962 |  19048 |   9855 |   94548859 |   94548860 |   19048 | 88550574
  10673962 |  22530 |   5084 |   94548857 |   94548858 |   22530 | 88748651
  10673962 |  31045 |   1951 |   94548861 |   94048571 |   31045 | 94027538
 242825710 |   2594 |  25106 |   94548866 |   94034826 |    2594 | 87472646
 242825710 |  25106 |  17366 |   94034826 |   94063224 |   25106 | 94003811
 242825711 |  13040 |  33264 |   94548884 |   94548885 |   13040 | 88275409
 242825711 |  17366 |  13040 |   94063224 |   94548884 |   17366 | 88395667
 242825711 |  32274 |  17422 |   94548886 |   94548889 |   32274 | 94031355
 242825711 |  33264 |  32274 |   94548885 |   94548886 |   33264 | 94034427
(18 rows)


select  pgr_dijkstra('select gid as id, source_osm as source,  target_osm as target, cost from routing.ways',94548856, 94548889);

select a.seq,a.path_seq from  pgr_dijkstra('select gid as id, source,  target, cost from routing.ways',6448, 17422) a;

 Schema |     Name     |   Result data type   |                                                                                                                        Argument data types                                                                                                                         |  Type
--------+--------------+----------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+--------
 public | pgr_dijkstra | SETOF pgr_costresult | edges_sql text, start_vid bigint, end_vid bigint, directed boolean, has_rcost boolean                                                                                                                                                                              | normal
 public | pgr_dijkstra | SETOF record         | edges_sql text, start_vid bigint, end_vid bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision                                                              | normal
 public | pgr_dijkstra | SETOF record         | edges_sql text, start_vid bigint, end_vid bigint, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision                                                                                | normal
 public | pgr_dijkstra | SETOF record         | edges_sql text, start_vid bigint, end_vids anyarray, directed boolean DEFAULT true, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision                          | normal
 public | pgr_dijkstra | SETOF record         | edges_sql text, start_vids anyarray, end_vid bigint, directed boolean DEFAULT true, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision                        | normal
 public | pgr_dijkstra | SETOF record         | edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean DEFAULT true, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision | normal
(6 rows)


---

WITH
    roadwayname (n) as (
       select 'CHURCH RD'::text
    ),
    fromname (n) as (
       select 'ARMSTRONG AVE'::text
    ),
    toname (n) as (
       select 'SIERRA AVE'::text
    ),
    fipscode (c) as (
       select '06107'::varchar
    ),
    max_dist (d) as (
       select 10::numeric
    ),
    cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             join fipscode on (fipscode.c = cf.fips)
             group by c.name),
    cnty_names as (
        select distinct id,name,ways.nodes,ways.bbox,ways.linestring
        from way_name_view
        join ways USING (id)
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
        select id,name,nodes,score,linestring
        from road_max_id
        join road_ranking USING (id,score)
    ),
    from_ranking as (
           select id, name, nodes, similarity(name,fm.n) as score,linestring
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
        select id,name,nodes,score,linestring
        from from_max_id
        join from_ranking USING (id,score)
    ),
    to_ranking as (
           select id, name, nodes, similarity(name,tm.n) as score,linestring
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
        select id,name,nodes,score,linestring
        from to_max_id
        join to_ranking USING (id,score)
    ),
    end_points_all_len as (
        select
          f.id as f_id ,f.name as f_name,f.nodes[1] as from_node,f.score as f_score,
          t.id as t_id ,t.name as t_name,t.nodes[1] as to_node,t.score as t_score
          from from_ranking_max f, to_ranking_max t
          order by f_score desc, t_score desc
    ),
    possibles (f_id,t_id,cost)as (
        select  f_id,t_id,max(dijk.agg_cost) as cost
        from
        end_points_all_len
        join
        pgr_dijkstra('
        with cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name and cf.fips ~* '|| quote_literal(06107) ||')
             group by c.name)
        select gid as id, source_osm as source,  target_osm as target, cost from routing.ways join cnty on (ways.the_geom && cnty.geom)'
        ,from_node, to_node)  dijk on (1=1)
        group by f_id,t_id
        )
   select  possibles.*,e.*  from possibles join end_points_all_len e USING (f_id,t_id)
   ;


--- hmm

WITH
    roadwayname (n) as (
       select 'CHURCH RD'::text
    ),
    fromname (n) as (
       select 'ARMSTRONG AVE'::text
    ),
    toname (n) as (
       select 'SIERRA AVE'::text
    ),
    fipscode (c) as (
       select '06107'::varchar
    ),
    max_dist (d) as (
       select 10::numeric
    ),
    cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             join fipscode on (fipscode.c = cf.fips)
             group by c.name),
    cnty_names as (
        select distinct id,name,ways.nodes,ways.bbox,ways.linestring
        from way_name_view
        join ways USING (id)
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
        join road_ranking_max r1 on (r1.node=f.node)
        union
        select 2 as which, t.id as c_id,r2.id,t.name as c_name,r2.name,t.node,t.score as c_score,r2.score as score
        from to_ranking_max t
        join road_ranking_max r2 on (r2.node=t.node)
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
    end_nodes as (
        select u.which,node,max(score) as score,max(c_score) as c_score
        from unique_ends u
        join best_match_end b on (b.which!=u.which)
        group by u.which,node
    ),
    pairs as (
        select f.node as f_node,t.node as t_node
        from
        end_nodes t cross join start_nodes f
    ),
    paths as (
        select  f_node,t_node,max(dijk.agg_cost) as cost,
        st_linemerge( st_collect(w.the_geom) ) as geom
        from
        pairs p
        join
        pgr_dijkstra('
        with cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name and cf.fips ~* '|| quote_literal(06107) ||')
             group by c.name)
        select gid as id, source_osm as source,  target_osm as target, cost from routing.ways join cnty on (ways.the_geom && cnty.geom)'
        ,f_node, t_node)  dijk on (1=1)
        join routing.ways w on (dijk.edge = w.gid)
        group by f_node,t_node
        order by f_node,t_node
        )
   select f_node,t_node,cost,st_asewkt(geom),
      (st_length(st_transform(geom,32611)) * 0.000621371192) as len
   from paths

join
   end_points_all_len e USING (f_id,t_id)

-- seq, path_seq, node, edge, cost, agg_cost


-- join with original way ids?
    pairs as (
        select f.node as f_node,t.node as t_node,ff.id as f_id,tt.id as t_id
        from
        end_nodes t cross join start_nodes f
        join end_points_all tt on (t.which=tt.which and t.node=tt.node and t.score=tt.score and t.c_score=tt.c_score)
        join end_points_all ff on (f.which=ff.which and f.node=ff.node and f.score=ff.score and f.c_score=ff.c_score)
    )


---- okay try it out with the RAM maxifying pairs


WITH
    roadwayname (n) as (
       select 'MAIN ST'::text -- which should probably be RAILROAD AVE!
    ),
    fromname (n) as (
       select 'BOUQUET CANYON RD'::text
    ),
    toname (n) as (
       select '15TH ST'::text
    ),
    fipscode (c) as (
       select '06037'::varchar
    ),
    max_dist (d) as (
       select 10::numeric
    ),
    cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             join fipscode on (fipscode.c = cf.fips)
             group by c.name),
    cnty_names as (
        select distinct id,name,ways.nodes,ways.bbox,ways.linestring
        from way_name_view
        join ways USING (id)
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
        join road_ranking_max r1 on (r1.node=f.node)
        union
        select 2 as which, t.id as c_id,r2.id,t.name as c_name,r2.name,t.node,t.score as c_score,r2.score as score
        from to_ranking_max t
        join road_ranking_max r2 on (r2.node=t.node)
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
    end_nodes as (
        select u.which,node,max(score) as score,max(c_score) as c_score
        from unique_ends u
        join best_match_end b on (b.which!=u.which)
        group by u.which,node
    ),
    pairs as (
        select f.node as f_node,t.node as t_node
        from
        end_nodes t cross join start_nodes f
    ),
    paths as (
        select  f_node,t_node,max(dijk.agg_cost) as cost,
        st_linemerge( st_collect(w.the_geom) ) as geom
        from
        pairs p
        join
        pgr_dijkstra('
        with cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name and cf.fips ~* '|| quote_literal(06037) ||')
             group by c.name)
        select gid as id, source_osm as source,  target_osm as target, cost from routing.ways join cnty on (ways.the_geom && cnty.geom)'
        ,f_node, t_node)  dijk on (1=1)
        join routing.ways w on (dijk.edge = w.gid)
        group by f_node,t_node
        order by f_node,t_node
        )
   select f_node,t_node,cost,st_asewkt(geom),
      (st_length(st_transform(geom,32611)) * 0.000621371192) as len
   from paths

--- okay, gives null result


--- join with road,from,to matched names


WITH
    roadwayname (n) as (
       select 'CHURCH RD'::text
    ),
    fromname (n) as (
       select 'ARMSTRONG AVE'::text
    ),
    toname (n) as (
       select 'SIERRA AVE'::text
    ),
    fipscode (c) as (
       select '06107'::varchar
    ),
    max_dist (d) as (
       select 10::numeric
    ),
    cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             join fipscode on (fipscode.c = cf.fips)
             group by c.name),
    cnty_names as (
        select distinct id,name,ways.nodes,ways.bbox,ways.linestring
        from way_name_view
        join ways USING (id)
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
        join road_ranking_max r1 on (r1.node=f.node)
        union
        select 2 as which, t.id as c_id,r2.id,t.name as c_name,r2.name,t.node,t.score as c_score,r2.score as score
        from to_ranking_max t
        join road_ranking_max r2 on (r2.node=t.node)
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
    ),
    pairs as (
        select f.node as f_node,t.node as t_node,f.id as from_id,t.id as to_id,
        f.name as from_road_name,f.c_name as from_crossing_name,
        t.name as to_road_name,t.c_name as to_crossing_name
        from
        end_nodes_2 t cross join start_nodes_2 f
    ),
    paths as (
        select p.*,  max(dijk.agg_cost) as cost,
        st_linemerge( st_collect(w.the_geom) ) as geom
        from
        pairs p
        join
        pgr_dijkstra('
        with cnty as (select ST_ENVELOPE(ST_Union(geom4326)) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name and cf.fips ~* '|| quote_literal(06107) ||')
             group by c.name)
        select gid as id, source_osm as source,  target_osm as target, cost from routing.ways join cnty on (ways.the_geom && cnty.geom)'
        ,f_node, t_node)  dijk on (1=1)
        join routing.ways w on (dijk.edge = w.gid)
        group by f_node,t_node,from_id,to_id,from_road_name,from_crossing_name,to_road_name,to_crossing_name
        )
   select
       f_node,  t_node,  from_id,  to_id, from_road_name, from_crossing_name, to_road_name, to_crossing_name,
       (st_length(st_transform(geom,32611)) * 0.000621371192) as len,
     -- geom
       st_asewkt(geom)
   from paths
   order by len


--- convert to a function
-- see ./find_road_from_to_pgrouting.sql
--

select (res)  from (select find_road_from_to_osm_pgrouting('CHURCH RD', 'ARMSTRONG AVE', 'SIERRA AVE', '06107') as res) a ;

select *  from find_road_from_to_osm_pgrouting('SUCCESS DR', 'SPRINGVILLE AVE', 'RD 248', '06107') a ;
