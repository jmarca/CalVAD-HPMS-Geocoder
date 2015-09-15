# Extract a test set

The OSM and CT road data sets are huge.  To make a small test set, I
am extracting a box.

```
crs=# select count(*),"group",ST_Extent(wkb_geometry) as bbox from crs_index group by "group" order by count;

+-------+-------+----------------------------------------------------------------------+
| count | group |                                 bbox                                 |
+-------+-------+----------------------------------------------------------------------+
|   ... | ...   | ...                                                                  |
|    21 | 11Q   | BOX(44788.85546875 -242519.9375,90152.1953125 -195870.390625)        |
|    21 | 07J   | BOX(-131048.375 35687.53515625,-86908.625 82572.7109375)             |
|    21 | 04K   | BOX(-263440.78125 -8195.1630859375,-218338.203125 39373.08203125)    |
|    22 | 11P   | BOX(44544.6015625 -196224.921875,89664.2578125 -149567.71875)        |
|   ... | ...   | ...                                                                  |
+-------+-------+----------------------------------------------------------------------+

```


Going with group `11Q`, the spatial extent argument becomes the
following.

Actually no, going with `09Q`, `BOX(-120.500992371782 35.8332909935652,-120.000969732654 36.2502091197714)`.


Okay, still not so clean.  How about all of Tulare County?

```
crs=# select name,ST_Extent(wkb_geometry) from multipolygons where name = 'Tulare' group by name;
  name  |                    st_extent
--------+--------------------------------------------------
 Tulare | BOX(-119.392846 36.123467,-119.295803 36.247664)
(1 row)

```
No, that got the city, I think.

```
crs=# select countyfp,ST_Extent(st_transform(wkb_geometry,4326)) from roads_jun_2015 where countyfp='107' group by countyfp;
 countyfp |                                 st_extent
----------+---------------------------------------------------------------------------
 107      | BOX(-119.573194000461 35.7894520004385,-118.00065799957 36.7416250002745)
```



So the complete call to load test OSM data is


```
export PGUSER=slash
export PGHOST=127.0.0.1
dropdb -U slash -h $PGHOST crs_small
createdb -U $PGUSER -h $PGHOST crs_small
psql -d crs_small -U $PGUSER  -h $PGHOST -c 'CREATE EXTENSION postgis;'
psql -d crs_small -U $PGUSER  -h $PGHOST -c 'CREATE EXTENSION hstore;'
psql -d crs_small -U $PGUSER  -h $PGHOST -c 'CREATE EXTENSION pg_trgm;'

PG_USE_COPY=yes \
ogr2ogr -progress \
  -f PostgreSQL PG:"dbname=crs_small user=$PGUSER host=$PGHOST" \
  -overwrite \
  -spat -119.573194000461 35.7894520004385 -118.00065799957 36.7416250002745 \
  -spat_srs 'EPSG:4326' \
  california-latest.osm.pbf \
  -lco COLUMN_TYPES=other_tags=hstore -oo MAX_TMPFILE_SIZE=5000

```

Writing the OSM data to the database will take some time, as there is
a lot of data to sift through looking for this small bounding box.

The Caltrans CRS grid data is loaded in a similar way using ogr2ogr.

```
ogr2ogr -progress -f PostgreSQL PG:"dbname=crs_small user=$PGUSER host=$PGHOST" \
        -spat -119.573194000461 35.7894520004385 -118.00065799957 36.7416250002745 \
        -spat_srs 'EPSG:4326'  \
        CRS_Index.shp

```

That should load fairly quickly.  Finally, load the Caltrans CRS
lines.  This command can't use the -progress flag because ogr2ogr
complains that it will take too long, but it goes by really fast anyway.

```
ogr2ogr -f PostgreSQL PG:"dbname=crs_small user=$PGUSER host=$PGHOST" \
        -spat -119.573194000461 35.7894520004385 -118.00065799957 36.7416250002745 \
        -spat_srs 'EPSG:4326'  \
        Roads_Jun30_2015_D06.gdb.zip \
        -nln 'roads_jun_2015'

```

It is useful to have a common projection.

```
psql -d crs_small -U $PGUSER  -h $PGHOST -c 'alter table crs_index add column geom geometry(Polygon,4326);'
psql -d crs_small -U $PGUSER  -h $PGHOST -c 'update crs_index set geom = st_transform(wkb_geometry,4326);'

psql -d crs_small -U $PGUSER  -h $PGHOST -c 'alter table roads_jun_2015 add column geom geometry(Multilinestring,4326);'
psql -d crs_small -U $PGUSER  -h $PGHOST -c 'update roads_jun_2015 set geom = st_transform(wkb_geometry,4326);'

```


Next check that all is well.  These should be in one of the tests.

```

crs_small=# select count(*) from lines;
 count
-------
  5501
(1 row)

crs_small=# select count(*) from points;
 count
-------
   834
(1 row)

crs_small=# select count(*) from roads_jun_2015;
 count
-------
 12844
(1 row)

crs_small=# select count(*) from crs_index;
 count
-------
    12
(1 row)

```
