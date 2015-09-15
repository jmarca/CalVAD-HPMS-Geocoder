WITH
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    sim_ranking as (
           select osm_id,name,other_tags,wkb_geometry, similarity(r.name,'AVENUE 56') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(r.name,'AVENUE 56') > 0.1
           UNION
           select osm_id,r1.other_tags -> 'name_1' as name, other_tags,wkb_geometry, similarity(r1.other_tags -> 'name_1','AVENUE 56') as score
           from lines r1
           join cnty on (r1.wkb_geometry && cnty.geom)
           where similarity(r1.other_tags -> 'name_1','AVENUE 56') > 0.1
           order by score desc),
    max_sim as (select max(score) as max_sim from sim_ranking),
    s1_segments as (select s.* from sim_ranking s, max_sim where score = max_sim),
---    s1_g as (select name, ST_MakeLine(ST_LineMerge(wkb_geometry)) as geom from s1_segments group by name),
---
--- first intersection
---
    from_ranking as (select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'ROAD 192') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'ROAD 192') > 0.1
           UNION
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'ROAD 192') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'ROAD 192') > 0.1
           order by score desc),
    max_sim_from as (select max(score) as max_sim from from_ranking ),
    s2_segments as (select distinct * from max_sim_from, from_ranking where score = max_sim),
    -- s2_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s2_segments group by name limit 1),
    --
    -- second intersection
    --
    to_ranking as (select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'SHWY 65') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'SHWY 65') > 0.1
           UNION
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'SHWY 65') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'SHWY 65') > 0.1
           order by score desc),
    max_sim_to as (select max(score) as max_sim from to_ranking),
    s3_segments as (select distinct * from max_sim_to, to_ranking where score = max_sim),
    -- s3_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s3_segments group by name limit 1),
    --
    -- nearness of s1 to s2
    --
    m2 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s2_dist from s1_segments s,s2_segments ss order by s2_dist limit 1),
    -- nearness of s1 to s3
    m3 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s3_dist from s1_segments s,s3_segments ss order by s3_dist limit 1),
    --
    -- maximum inclusive distance
    --
    maximal as (select st_distance(m2.pt,m3.pt) as maxdist from m2,m3 limit 1),
    keep_segs as (select distinct s.*,
                  st_distance(s.wkb_geometry,m2.pt) as s2_dist,
                  st_distance(s.wkb_geometry,m3.pt) as s3_dist
                  from s1_segments s,m2,m3 ),
    closest_segs as (select s.* from keep_segs s, maximal
                     where  s2_dist <= maxdist and s3_dist <= maxdist),
    pickme as (select s.name,
                      st_linemerge(st_union(s.wkb_geometry)) as geom
               from closest_segs s
               group by name
               ),
    trimmed as (
       select s.name,
              ST_LineSubstring(
                  s.geom,
                  ST_LineLocatePoint(s.geom,
                                     m2.pt),
                  ST_LineLocatePoint(s.geom,
                                     m3.pt)
              ) as geom
       from
       pickme s,m2,m3
   )

select name,(st_length(st_transform(s.geom,32611)) * 0.000621371192) as len
       from trimmed s;


-- need to have strict less than in the closest segs query.  The
-- problem is there is one way that actually includes the desired
-- section, and another that touches the end then tails off to the
-- mountains, but the shortest distance is exactly the length of the
-- road.


--- Try with different roads
select coalesce ( alternative_route_name_txt,route_id,aadt_cmt) as bleh,aadt_cmt,section_length from hpms where county_code=107 and aadt is not null and aadt > 0 order by random();

 CHURCH RD                                 | ARMSTRONG AVE to URL @ SIERRA AVE                   |                    1
 PROSPERITY AVE                            |                                                     |                 0.14
 SPRUCE ROAD                               | URL @ PALM ST to URL @ MYER RD                      |                 3.49
 216R                                      | TUL-216-2.46/TUL-216-6.95                           |   0.0300000000000002
 SUCCESS DR                                | SPRINGVILLE AVE to .55M W/RD 248                    |                 1.63
 AVENUE 116                                | ROAD 264 to DIAGONAL 254                            |                 0.86

WITH
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    sim_ranking as (
           select osm_id,name,other_tags,wkb_geometry, similarity(r.name,'CHURCH ROAD') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(r.name,'CHURCH ROAD') > 0.1
           UNION
           select osm_id,r1.other_tags -> 'name_1' as name, other_tags,wkb_geometry, similarity(r1.other_tags -> 'name_1','CHURCH ROAD') as score
           from lines r1
           join cnty on (r1.wkb_geometry && cnty.geom)
           where similarity(r1.other_tags -> 'name_1','CHURCH ROAD') > 0.1
           order by score desc),
    max_sim as (select max(score) as max_sim from sim_ranking),
    s1_segments as (select s.* from sim_ranking s, max_sim where score = max_sim),
---    s1_g as (select name, ST_MakeLine(ST_LineMerge(wkb_geometry)) as geom from s1_segments group by name),
---
--- first intersection
---
    from_ranking as (
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'ARMSTRONG AVENUE') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'ARMSTRONG AVENUE') > 0.1
           UNION
           select r2.wkb_geometry,r2.osm_id,r2.other_tags -> 'name_1' as name, similarity(r2.other_tags -> 'name_1','ARMSTRONG AVENUE') as score
           from lines r2
           join cnty on (r2.wkb_geometry && cnty.geom)
           where similarity(r2.other_tags -> 'name_1','ARMSTRONG AVENUE') > 0.1
           UNION
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'ARMSTRONG AVENUE') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'ARMSTRONG AVENUE') > 0.1
           order by score desc),
    max_sim_from as (select max(score) as max_sim from from_ranking ),
    s2_segments as (select distinct * from max_sim_from, from_ranking where score = max_sim),
    -- s2_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s2_segments group by name limit 1),
    --
    -- second intersection
    --
    to_ranking as (select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'SIERRA AVENUE') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'SIERRA AVENUE') > 0.1
           UNION
           select r2.wkb_geometry,r2.osm_id,r2.other_tags -> 'name_1' as name, similarity(r2.other_tags -> 'name_1','SIERRA AVENUE') as score
           from lines r2
           join cnty on (r2.wkb_geometry && cnty.geom)
           where similarity(r2.other_tags -> 'name_1','SIERRA AVENUE') > 0.1
           UNION
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'SIERRA AVENUE') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'SIERRA AVENUE') > 0.1
           order by score desc),
    max_sim_to as (select max(score) as max_sim from to_ranking),
    s3_segments as (select distinct * from max_sim_to, to_ranking where score = max_sim),
    -- s3_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s3_segments group by name limit 1),
    --
    -- nearness of s1 to s2
    --
    m2 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s2_dist from s1_segments s,s2_segments ss order by s2_dist limit 1),
    -- nearness of s1 to s3
    m3 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s3_dist from s1_segments s,s3_segments ss order by s3_dist limit 1),
    --
    -- maximum inclusive distance
    --
    maximal as (select st_distance(m2.pt,m3.pt) as maxdist from m2,m3 limit 1),
    keep_segs as (select distinct s.*,
                  st_distance(s.wkb_geometry,m2.pt) as s2_dist,
                  st_distance(s.wkb_geometry,m3.pt) as s3_dist
                  from s1_segments s,m2,m3 ),
    closest_segs as (select s.* from keep_segs s, maximal
                     where  s2_dist <= maxdist and s3_dist <= maxdist),
    pickme as (select s.name,
                      st_linemerge(st_union(s.wkb_geometry)) as geom
               from closest_segs s
               group by name
               ),
    trimmed as (
       select s.name,
              ST_LineSubstring(
                  s.geom,
                  ST_LineLocatePoint(s.geom,
                                     m2.pt),
                  ST_LineLocatePoint(s.geom,
                                     m3.pt)
              ) as geom
       from
       pickme s,m2,m3
   )

select name,(st_length(st_transform(s.geom,32611)) * 0.000621371192) as len
       from pickme s;



WITH
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    sim_ranking as (
           select fullname as name,r.geom as wkb_geometry, similarity(r.fullname,'CHURCH ROAD') as score
           from roads_jun_2015 r
           join cnty on (r.geom && cnty.geom)
           where similarity(r.fullname,'CHURCH ROAD') > 0.1
           order by score desc),
    max_sim as (select max(score) as max_sim from sim_ranking),
    s1_segments as (select s.* from sim_ranking s, max_sim where score > max_sim - 0.1),
---    s1_g as (select name, ST_MakeLine(ST_LineMerge(wkb_geometry)) as geom from s1_segments group by name),
---
--- first intersection
---
    from_ranking as (
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'ARMSTRONG AVENUE') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'ARMSTRONG AVENUE') > 0.1
           UNION
           select r2.wkb_geometry,r2.osm_id,r2.other_tags -> 'name_1' as name, similarity(r2.other_tags -> 'name_1','ARMSTRONG AVENUE') as score
           from lines r2
           join cnty on (r2.wkb_geometry && cnty.geom)
           where similarity(r2.other_tags -> 'name_1','ARMSTRONG AVENUE') > 0.1
           UNION
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'ARMSTRONG AVENUE') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'ARMSTRONG AVENUE') > 0.1
           order by score desc),
    max_sim_from as (select max(score) as max_sim from from_ranking ),
    s2_segments as (select distinct * from max_sim_from, from_ranking where score > max_sim - 0.1),
    -- s2_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s2_segments group by name limit 1),
    --
    -- second intersection
    --
    to_ranking as (select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'SIERRA AVENUE') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'SIERRA AVENUE') > 0.1
           UNION
           select r2.wkb_geometry,r2.osm_id,r2.other_tags -> 'name_1' as name, similarity(r2.other_tags -> 'name_1','SIERRA AVENUE') as score
           from lines r2
           join cnty on (r2.wkb_geometry && cnty.geom)
           where similarity(r2.other_tags -> 'name_1','SIERRA AVENUE') > 0.1
           UNION
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'SIERRA AVENUE') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'SIERRA AVENUE') > 0.1
           order by score desc),
    max_sim_to as (select max(score) as max_sim from to_ranking),
    s3_segments as (select distinct * from max_sim_to, to_ranking where score > max_sim - 0.1),
    -- s3_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s3_segments group by name limit 1),
    --
    -- nearness of s1 to s2
    --
    m2 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s2_dist from s1_segments s,s2_segments ss order by s2_dist limit 1),
    -- nearness of s1 to s3
    m3 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s3_dist from s1_segments s,s3_segments ss order by s3_dist limit 1),
    --
    -- maximum inclusive distance
    --
    maximal as (select st_distance(m2.pt,m3.pt) as maxdist from m2,m3 limit 1),
    keep_segs as (select distinct s.*,
                  st_distance(s.wkb_geometry,m2.pt) as s2_dist,
                  st_distance(s.wkb_geometry,m3.pt) as s3_dist
                  from s1_segments s,m2,m3 ),
    closest_segs as (select s.* from keep_segs s, maximal
                     where  s2_dist < maxdist and s3_dist < maxdist),
    pickme as (select --s.name,
                      st_linemerge(st_union(s.wkb_geometry)) as geom
               from closest_segs s
               --               group by name
               ),
    trimmed as (
       select --s.name,
              ST_LineSubstring(
                  s.geom,
                  ST_LineLocatePoint(s.geom,
                                     m2.pt),
                  ST_LineLocatePoint(s.geom,
                                     m3.pt)
              ) as geom
       from
       pickme s,m2,m3
   )

select --name,
       st_asewkt(s.geom),
       (st_length(st_transform(s.geom,32611)) * 0.000621371192) as len
       from pickme s;

--  SUCCESS DR                                | SPRINGVILLE AVE to .55M W/RD 248                    |                 1.63

WITH
    cnty as (select ST_Union(geom4326) as geom
             from public.carb_counties_aligned_03 c
             join counties_fips cf  on (cf.name ~* c.name)
             where fips = '06107' group by c.name),
    sim_ranking as (
           select osm_id,name,other_tags,wkb_geometry, similarity(r.name,'SUCCESS DR') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(r.name,'SUCCESS DR') > 0.1
           UNION
           select osm_id,r1.other_tags -> 'name_1' as name, other_tags,wkb_geometry, similarity(r1.other_tags -> 'name_1','SUCCESS DR') as score
           from lines r1
           join cnty on (r1.wkb_geometry && cnty.geom)
           where similarity(r1.other_tags -> 'name_1','SUCCESS DR') > 0.1
           order by score desc),
    -- sim_ranking2 as (
    --        select fullname as name,r.geom as wkb_geometry, similarity(r.fullname,'SUCCESS DR') as score
    --        from roads_jun_2015 r
    --        join cnty on (r.geom && cnty.geom)
    --        where similarity(r.fullname,'SUCCESS DR') > 0.1
    --        order by score desc),
    max_sim as (select max(score) as max_sim from sim_ranking),
    s1_segments as (select s.* from sim_ranking s, max_sim where score > max_sim - 0.1),
---    s1_g as (select name, ST_MakeLine(ST_LineMerge(wkb_geometry)) as geom from s1_segments group by name),
---
--- first intersection
---
    from_ranking as (
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'SPRINGVILLE AVE') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'SPRINGVILLE AVE') > 0.1
           UNION
           select r2.wkb_geometry,r2.osm_id,r2.other_tags -> 'name_1' as name, similarity(r2.other_tags -> 'name_1','SPRINGVILLE AVE') as score
           from lines r2
           join cnty on (r2.wkb_geometry && cnty.geom)
           where similarity(r2.other_tags -> 'name_1','SPRINGVILLE AVE') > 0.1
           UNION
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'SPRINGVILLE AVE') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'SPRINGVILLE AVE') > 0.1
           order by score desc),
    max_sim_from as (select max(score) as max_sim from from_ranking ),
    s2_segments as (select distinct * from max_sim_from, from_ranking where score > max_sim - 0.1),
    -- s2_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s2_segments group by name limit 1),
    --
    -- second intersection
    --
    to_ranking as (select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'RD 248') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'RD 248') > 0.1
           UNION
           select r2.wkb_geometry,r2.osm_id,r2.other_tags -> 'name_1' as name, similarity(r2.other_tags -> 'name_1','RD 248') as score
           from lines r2
           join cnty on (r2.wkb_geometry && cnty.geom)
           where similarity(r2.other_tags -> 'name_1','RD 248') > 0.1
           UNION
           select r.wkb_geometry,r.osm_id,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'RD 248') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'RD 248') > 0.1
           order by score desc),
    max_sim_to as (select max(score) as max_sim from to_ranking),
    s3_segments as (select distinct * from max_sim_to, to_ranking where score > max_sim - 0.1),
    -- s3_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s3_segments group by name limit 1),
    --
    -- nearness of s1 to s2
    --
    m2 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s2_dist from s1_segments s,s2_segments ss order by s2_dist limit 1),
    -- nearness of s1 to s3
    m3 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s3_dist from s1_segments s,s3_segments ss order by s3_dist limit 1),
    --
    -- maximum inclusive distance
    --
    maximal as (select st_distance(m2.pt,m3.pt) as maxdist from m2,m3 limit 1),
    keep_segs as (select distinct s.*,
                  st_distance(s.wkb_geometry,m2.pt) as s2_dist,
                  st_distance(s.wkb_geometry,m3.pt) as s3_dist
                  from s1_segments s,m2,m3 ),
    closest_segs as (select s.* from keep_segs s, maximal
                     where  s2_dist < maxdist and s3_dist < maxdist),
    pickme as (select --s.name,
                      st_linemerge(st_union(s.wkb_geometry)) as geom
               from closest_segs s
               --               group by name
               ),
    trimmed as (
       select --s.name,
              ST_LineSubstring(
                  s.geom,
                  ST_LineLocatePoint(s.geom,
                                     m2.pt),
                  ST_LineLocatePoint(s.geom,
                                     m3.pt)
              ) as geom
       from
       pickme s,m2,m3
   )

select --name,
       st_asewkt(s.geom),
       (st_length(st_transform(s.geom,32611)) * 0.000621371192) as len
       from pickme s;


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
    from_ranking as (
           select r.wkb_geometry,r.ogc_fid,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'PALM STREET') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'PALM STREET') > 0.1
           UNION
           select r2.wkb_geometry,r2.ogc_fid,r2.other_tags -> 'name_1' as name, similarity(r2.other_tags -> 'name_1','PALM STREET') as score
           from lines r2
           join cnty on (r2.wkb_geometry && cnty.geom)
           where similarity(r2.other_tags -> 'name_1','PALM STREET') > 0.1
           UNION
           select r.wkb_geometry,r.ogc_fid,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'PALM STREET') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'PALM STREET') > 0.1
           order by score desc),
    max_sim_from as (select max(score) as max_sim from from_ranking ),
    s2_segments as (select distinct * from max_sim_from, from_ranking where score > max_sim - 0.1),
    -- s2_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s2_segments group by name limit 1),
    --
    -- second intersection
    --
    to_ranking as (
           select r.wkb_geometry,r.ogc_fid,coalesce(r.name,r.other_tags -> 'ref') as name, similarity(coalesce(r.name,r.other_tags -> 'ref'),'MYER RD') as score
           from lines r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'MYER RD') > 0.1
           UNION
           select r2.wkb_geometry,r2.ogc_fid,r2.other_tags -> 'name_1' as name, similarity(r2.other_tags -> 'name_1','MYER RD') as score
           from lines r2
           join cnty on (r2.wkb_geometry && cnty.geom)
           where similarity(r2.other_tags -> 'name_1','MYER RD') > 0.1
           UNION
           select r.wkb_geometry,r.ogc_fid,coalesce(r.name,r.other_tags -> 'ref'), similarity(coalesce(r.name,r.other_tags -> 'ref'),'MYER RD') as score
           from multilinestrings r
           join cnty on (r.wkb_geometry && cnty.geom)
           where similarity(coalesce(r.name,r.other_tags -> 'ref'),'MYER RD') > 0.1
           order by score desc),
    max_sim_to as (select max(score) as max_sim from to_ranking),
    s3_segments as (select distinct * from max_sim_to, to_ranking where score > max_sim - 0.1),
    -- s3_g as (select name, st_makeline(st_linemerge(wkb_geometry)) as geom from s3_segments group by name limit 1),
    --
    -- nearness of s1 to s2
    --
    m2 as (select s.ogc_fid as fid_s, ss.ogc_fid as fid_ss, st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s2_dist from s1_segments s,s2_segments ss order by s2_dist limit 1),
    -- nearness of s1 to s3
    m3 as (select st_ClosestPoint(s.wkb_geometry,ss.wkb_geometry) as pt, st_distance(s.wkb_geometry,ss.wkb_geometry) as s3_dist from s1_segments s,s3_segments ss order by s3_dist limit 1),
    --
    -- maximum inclusive distance
    --
    maximal as (select st_distance(m2.pt,m3.pt) as maxdist from m2,m3 limit 1),
    keep_segs as (select distinct s.*,
                  st_distance(s.wkb_geometry,m2.pt) as s2_dist,
                  st_distance(s.wkb_geometry,m3.pt) as s3_dist
                  from s1_segments s,m2,m3 ),
    closest_segs as (select s.* from keep_segs s, maximal
                     where  s2_dist < maxdist and s3_dist < maxdist),
    pickme as (select --s.name,
                      st_linemerge(st_union(s.wkb_geometry)) as geom
               from closest_segs s
               --               group by name
               ),
    trimmed as (
       select --s.name,
              ST_LineSubstring(
                  s.geom,
                  ST_LineLocatePoint(s.geom,
                                     m2.pt),
                  ST_LineLocatePoint(s.geom,
                                     m3.pt)
              ) as geom
       from
       pickme s,m2,m3
   )

select --name,
       st_asewkt(s.geom),
       (st_length(st_transform(s.geom,32611)) * 0.000621371192) as len
       from pickme s;
