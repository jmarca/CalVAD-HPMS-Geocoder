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
