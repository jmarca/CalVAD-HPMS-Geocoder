
explain analyze
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
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             join fipscode on (fipscode.c = cf.fips)
             group by c.name),
    roadways as (
        select *
        from ways join cnty on (ways.bbox && cnty.geom)
        where tags ? 'highway'
    ),
    tag_values as (
        select id as osm_id, svals(tags) as name, skeys(tags) as key from roadways
    )
select count(*) from tag_values;

                                                                   QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=80.37..80.38 rows=1 width=0) (actual time=842.018..842.018 rows=1 loops=1)
   CTE fipscode
     ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.001..0.001 rows=1 loops=1)
   CTE cnty
     ->  HashAggregate  (cost=17.14..17.15 rows=1 width=48571) (actual time=2.409..2.410 rows=1 loops=1)
           Group Key: c.name
           ->  Nested Loop  (cost=0.03..17.13 rows=1 width=48571) (actual time=1.638..2.285 rows=1 loops=1)
                 Join Filter: (cf.name ~* (c.name)::text)
                 Rows Removed by Join Filter: 101
                 ->  Hash Join  (cost=0.03..1.84 rows=1 width=8) (actual time=0.047..0.051 rows=1 loops=1)
                       Hash Cond: ((cf.fips)::text = (fipscode.c)::text)
                       ->  Seq Scan on counties_fips cf  (cost=0.00..1.58 rows=58 width=14) (actual time=0.009..0.020 rows=58 loops=1)
                       ->  Hash  (cost=0.02..0.02 rows=1 width=32) (actual time=0.007..0.007 rows=1 loops=1)
                             Buckets: 1024  Batches: 1  Memory Usage: 1kB
                             ->  CTE Scan on fipscode  (cost=0.00..0.02 rows=1 width=32) (actual time=0.004..0.005 rows=1 loops=1)
                 ->  Seq Scan on carb_counties_aligned_03 c  (cost=0.00..14.02 rows=102 width=48571) (actual time=0.003..0.046 rows=102 loops=1)
   CTE roadways
     ->  Nested Loop  (cost=4.34..35.69 rows=1 width=772) (actual time=15.834..46.526 rows=18583 loops=1)
           ->  CTE Scan on cnty  (cost=0.00..0.02 rows=1 width=32) (actual time=2.444..2.445 rows=1 loops=1)
           ->  Bitmap Heap Scan on ways  (cost=4.34..35.66 rows=1 width=740) (actual time=13.384..39.993 rows=18583 loops=1)
                 Recheck Cond: (bbox && cnty.geom)
                 Filter: (tags ? 'highway'::text)
                 Rows Removed by Filter: 58023
                 Heap Blocks: exact=7123
                 ->  Bitmap Index Scan on idx_ways_bbox  (cost=0.00..4.34 rows=8 width=0) (actual time=11.900..11.900 rows=76606 loops=1)
                       Index Cond: (bbox && cnty.geom)
   CTE tag_values
     ->  CTE Scan on roadways  (cost=0.00..5.02 rows=1000 width=40) (actual time=15.875..806.541 rows=110259 loops=1)
   ->  CTE Scan on tag_values  (cost=0.00..20.00 rows=1000 width=0) (actual time=15.878..835.659 rows=110259 loops=1)
 Planning time: 0.518 ms
 Execution time: 1088.296 ms
(31 rows)



explain analyze
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
        select id as osm_id, svals(tags) as name, skeys(tags) as key from roadways  join cnty on (roadways.bbox && cnty.geom)
    )
select count(*) from tag_values;
-- slight test of order of limitig boxes.  second way is faster

-------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=8127.76..8127.77 rows=1 width=0) (actual time=98.391..98.391 rows=1 loops=1)
   CTE fipscode
     ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.001..0.001 rows=1 loops=1)
   CTE cnty
     ->  HashAggregate  (cost=17.14..17.15 rows=1 width=48571) (actual time=1.214..1.215 rows=1 loops=1)
           Group Key: c.name
           ->  Nested Loop  (cost=0.03..17.13 rows=1 width=48571) (actual time=0.817..1.141 rows=1 loops=1)
                 Join Filter: (cf.name ~* (c.name)::text)
                 Rows Removed by Join Filter: 101
                 ->  Hash Join  (cost=0.03..1.84 rows=1 width=8) (actual time=0.022..0.024 rows=1 loops=1)
                       Hash Cond: ((cf.fips)::text = (fipscode.c)::text)
                       ->  Seq Scan on counties_fips cf  (cost=0.00..1.58 rows=58 width=14) (actual time=0.004..0.005 rows=58 loops=1)
                       ->  Hash  (cost=0.02..0.02 rows=1 width=32) (actual time=0.004..0.004 rows=1 loops=1)
                             Buckets: 1024  Batches: 1  Memory Usage: 1kB
                             ->  CTE Scan on fipscode  (cost=0.00..0.02 rows=1 width=32) (actual time=0.002..0.002 rows=1 loops=1)
                 ->  Seq Scan on carb_counties_aligned_03 c  (cost=0.00..14.02 rows=102 width=48571) (actual time=0.002..0.020 rows=102 loops=1)
   CTE roadways
     ->  Seq Scan on ways  (cost=0.00..8080.57 rows=77 width=740) (actual time=0.005..20.819 rows=18583 loops=1)
           Filter: (tags ? 'highway'::text)
           Rows Removed by Filter: 58023
   CTE tag_values
     ->  Nested Loop  (cost=0.00..7.52 rows=1000 width=40) (actual time=1.251..61.587 rows=110259 loops=1)
           Join Filter: (roadways.bbox && cnty.geom)
           ->  CTE Scan on cnty  (cost=0.00..0.02 rows=1 width=32) (actual time=1.235..1.236 rows=1 loops=1)
           ->  CTE Scan on roadways  (cost=0.00..1.54 rows=77 width=72) (actual time=0.006..29.912 rows=18583 loops=1)
   ->  CTE Scan on tag_values  (cost=0.00..20.00 rows=1000 width=0) (actual time=1.253..92.677 rows=110259 loops=1)
 Planning time: 0.199 ms
 Execution time: 100.056 ms
(28 rows)

-- order of magnitude faster, because order of magnitude fewer geometries to compare, I guess
