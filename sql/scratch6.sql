-- testing out the pgrouting function


WITH
    roadwayname (n) as (
       select 'SUCCESS DR'::text
    ),
    fromname (n) as (
       select 'SPRINGVILLE AVE'::text
    ),
    toname (n) as (
       select 'RD 248'::text
    ),
    fipscode (c) as (
       select '06107'::varchar
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
        order by score desc
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
    )

-- okay, that limits things a bit

-- see ./find_road_from_to_pgrouting.sql
--

select (res)  from (select find_road_from_to_osm_pgrouting('CHURCH RD', 'ARMSTRONG AVE', 'SIERRA AVE', '06107') as res) a ;

select *  from find_road_from_to_osm_pgrouting('SUCCESS DR', 'SPRINGVILLE AVE', 'RD 248', '06107') a ;


select * from  find_road_from_to_osm_pgrouting('MAIN ST', 'BOUQUET CANYON RD','15TH ST', '06037');
