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




This is slightly larger than the box corresponding to CRS grid index
number 940 (grid group 11P).  According to the CRS grid data, this
should contain 22 sub-grids, which means that there are lots of
highways and streets in this cell.

The above bounding box needs to be converted to a better known SRS
than 900914 to use with the OSM data:

```
BOX(-119.50096190029 36.2499498689845,-119.000934042247 36.6668715025746)
```


So the complete call to load test OSM data is


```
createdb -U slash crs_small
psql -d crs_small -U slash -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'

ogr2ogr -progress -f PostgreSQL PG:'dbname=crs_small user=slash' -overwrite \
        -spat -119.50096190029 36.2499498689845 -119.000934042247 36.6668715025746 \
        -spat_srs 'EPSG:4326'  \
        california-latest.osm.pbf \
        -lco COLUMN_TYPES=other_tags=hstore


```

The Caltrans CRS grid data is loaded in a similar way using ogr2ogr.

```
ogr2ogr -progress -f PostgreSQL PG:'dbname=crs_small user=slash' \
        -spat -119.50096190029 36.2499498689845 -119.000934042247 36.6668715025746 \
        -spat_srs 'EPSG:4326'  \
        CRS_Index.shp

```

And then the Caltrans CRS lines.

```
ogr2ogr -f PostgreSQL PG:'dbname=crs_small user=slash' \
        -spat -119.50096190029 36.2499498689845 -119.000934042247 36.6668715025746 \
        -spat_srs 'EPSG:4326'  \
        Roads_Jun30_2015_D06.gdb.zip \
        -nln 'roads_jun_2015'

```
