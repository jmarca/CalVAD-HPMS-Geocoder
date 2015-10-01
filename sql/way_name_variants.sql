-- create a table way name variants?  or make it a view?
-- can views have indices?

with
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
-- || quote_literal(name_pattern)
-- || '
    )
select id, name into way_name_variants from name_values ;



CREATE MATERIALIZED VIEW osm.way_name_view AS
with
    roadways as (
        select *
        from osm.ways
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
    )
select id, name from name_values ;
