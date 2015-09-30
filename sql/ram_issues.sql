select find_road_from_to_osm_trigram('MAIN ST', 'BOUQUET CANYON RD','15TH ST', '06037');
-- RAM crash!

WITH
    roadwayname (n) as (
       select 'MAIN ST'::text
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

    road_ranking as (
            select osm_id, name, similarity(name,rn.n) as score
            from name_values,roadwayname rn
    ),
    -- road_ranking_no_repeats as (
    --     select osm_id, max(score) as score
    --     from road_ranking
    --     where score > 0.1
    --     group by osm_id
    -- ),
    -- named_road_ranking_no_repeats as (
    --     select (array_agg(v.name))[1] as name, r.osm_id, r.score
    --     from road_ranking_no_repeats r
    --     join road_ranking v on (r.osm_id=v.osm_id and r.score=v.score)
    --     group by r.osm_id,r.score
    -- ),
    -- road_ranking_max as (
    --     select distinct roadways.*, r.score, r.name
    --     from named_road_ranking_no_repeats r
    --     join roadways on (osm_id=id)
    -- ),

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


explain analyze
with
    roadwayname (n) as (
       select 'MAIN ST'::text
    ),
    roadways as (
        select *
        from ways
        where tags ? 'highway'
    ),
    tag_values as (
        select id as id, svals(tags) as name, skeys(tags) as key
        from roadways
    ),
    name_values as (
        select id,name from tag_values
        where key ~* 'name' and
              key !~* '_direction' and
              key !~* '_type'
    ),
    road_ranking as (
            select id, name, similarity(name,rn.n) as score
            from name_values,roadwayname rn
    )
select id, name, score from road_ranking where score > 0.1;

                                                             QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------
 Planning time: 0.134 ms
 Execution time: 32315.846 ms

explain analyze
with
    roadwayname (n) as (
       select 'MAIN ST'::text
    ),
    road_ranking as (
            select wnv.id, wnv.name, similarity(wnv.name,rn.n) as score
            from way_name_view wnv,roadwayname rn
    )
select id, name, score from road_ranking where score > 0.1;
crs-# select id, name, score from road_ranking where score > 0.1;
                                                                 QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------------
 CTE Scan on road_ranking  (cost=37724.22..67117.41 rows=435455 width=44) (actual time=0.096..4520.343 rows=121652 loops=1)
   Filter: (score > 0.1::double precision)
   Rows Removed by Filter: 1184712
   CTE roadwayname
     ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.001..0.002 rows=1 loops=1)
   CTE road_ranking
     ->  Nested Loop  (cost=0.00..37724.21 rows=1306364 width=52) (actual time=0.027..3803.848 rows=1306364 loops=1)
           ->  CTE Scan on roadwayname rn  (cost=0.00..0.02 rows=1 width=32) (actual time=0.002..0.003 rows=1 loops=1)
           ->  Seq Scan on way_name_view wnv  (cost=0.00..21394.64 rows=1306364 width=20) (actual time=0.009..239.706 rows=1306364 loops=1)
 Planning time: 0.194 ms
 Execution time: 4537.926 ms
(11 rows)



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
          f.id as f_id ,f.name as f_name,f.nodes as f_nodes,f.score as f_score,
          t.id as t_id ,t.name as t_name,t.nodes as t_nodes,t.score as t_score,
          st_distance(st_transform(f.linestring,32611),
                      st_transform(t.linestring,32611)) * 0.000621371192 as len
          from from_ranking_max f, to_ranking_max t
          order by len, f_score desc, t_score desc
    ),
    end_points_close as (
        select * from end_points_all_len,max_dist
        where len < max_dist.d
    ),
    road_candidates as (
        select cn.name,cn.id,cn.nodes,similarity(cn.name,rn.n) as score,
               e1.f_score as crossing_score,
               e1.f_name as crossing_name,
               e1.f_id as crossing_id,
               'f' as which
        from cnty_names cn
        join end_points_close e1 on (cn.nodes && e1.f_nodes and cn.name != e1.f_name)
        join roadwayname rn on (1=1)
      union
        select cn.name,cn.id,cn.nodes,similarity(cn.name,rn.n) as score,
               e2.t_score as crossing_score,
               e2.t_name as crossing_name,
               e2.t_id as crossing_id,
               't' as which
        from cnty_names cn
        join end_points_close e2 on (cn.nodes && e2.t_nodes and cn.name != e2.t_name)
        join roadwayname rn on (1=1)
        order by score desc,crossing_score desc,id,crossing_id
    ),
    start_point as (
        select which,name,crossing_name,nodes,crossing_id,id
        from road_candidates
        order by score desc,crossing_score desc
        limit 1
    ),
    end_point as (
        select c.which,c.name,c.crossing_name,c.nodes,c.crossing_id,c.id
        from road_candidates c
        join start_point s on (c.which != s.which)
        order by score desc,crossing_score desc
        limit 1
    )
select st_distance(st_transform(sw.linestring,32611),
                   st_transform(ew.linestring,32611)) * 0.000621371192 as len,
       sp.name,sp.crossing_name,ep.name,ep.crossing_name
       from start_point sp
       join end_point ep on (1=1)
       join ways ew on (ep.id=ew.id)
       join ways sw on (sp.id=sw.id);

       len        | name | crossing_name |          name          | crossing_name
------------------+------+---------------+------------------------+----------------
 59.0638854743085 | Main | 15th          | Magic Mountain Parkway | Bouquet Canyon
(1 row)

-- aha, length of 59 miles is not okay...

select * from start_point
union
select * from end_point;
