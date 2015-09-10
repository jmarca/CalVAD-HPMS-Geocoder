# Extract a test set

The OSM and CT road data sets are huge.  To make a small test set, I
am extracting a box, using osmosis.

```
--bb left=-119.20224571511 right=-118.99875616017 top=36.6665969035 bottom=36.498423271789
```

This is slightly larger than the box corresponding to CRS grid index
number 940 (grid group 11P).  According to the CRS grid data, this
should contain a bunch (more than 20) sub-grids, which means that
there are lots of highways and streets in this cell.

So the complete call to load test OSM data is


```
createdb -U slash crs_small
psql -d crs_small -U slash -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'

ogr2ogr -progress -f PostgreSQL PG:'dbname=crs_small user=slash' -overwrite \
        -spat -119.20224571511 36.498423271789 -118.99875616017 36.6665969035 \
        california-latest.osm.pbf \
        -lco COLUMN_TYPES=other_tags=hstore


```

The test Caltrans CRS grid data is loaded in a similar way using ogr2ogr.

```
ogr2ogr -progress -f PostgreSQL PG:'dbname=crs_small user=slash' -overwrite \
        -spat -119.20224571511 36.498423271789 -118.99875616017 36.6665969035 \
        CRS_Index.shp

```

And then the Caltrans CRS lines.

```
ogr2ogr -progress -f PostgreSQL PG:'dbname=crs_small user=slash' -overwrite \
        -spat -119.20224571511 36.498423271789 -118.99875616017 36.6665969035 \
        CRS_Index.shp

```
