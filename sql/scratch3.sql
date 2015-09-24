-- trying out the new function

-- Random roads
select coalesce ( alternative_route_name_txt,route_id,aadt_cmt) as bleh,aadt_cmt,section_length from hpms where county_code=107 and aadt is not null and aadt > 0 order by random();

 CHURCH RD                                 | ARMSTRONG AVE to URL @ SIERRA AVE                   |                    1
 PROSPERITY AVE                            |                                                     |                 0.14
 SPRUCE ROAD                               | URL @ PALM ST to URL @ MYER RD                      |                 3.49
 216R                                      | TUL-216-2.46/TUL-216-6.95                           |   0.0300000000000002
 SUCCESS DR                                | SPRINGVILLE AVE to .55M W/RD 248                    |                 1.63
 AVENUE 116                                | ROAD 264 to DIAGONAL 254                            |                 0.86


-- find_road_from_to_osm_trigram(IN roadway text, IN from_road text, IN to_road text, IN in_county text)
select (res).name,(res).len  from (select find_road_from_to_osm_trigram('CHURCH RD', 'ARMSTRONG AVE', 'SIERRA AVE', '06107') as res) a ;
  name  |       len
--------+------------------
 Church | 1.00101155503447

select (res).name,(res).len  from (select find_road_from_to_osm_trigram('SUCCESS DR', 'SPRINGVILLE AVE', 'RD 248', '06107') as res) a ;

        name        |       len
--------------------+------------------
 East Success Drive | 1.73048776315583
(1 row)

select (res).name,(res).len  from (select find_road_from_to_osm_trigram('AVENUE 116', 'ROAD 264', 'DIAGONAL 254', '06107') as res) a ;
    name    |       len
------------+------------------
 Avenue 116 | 1.42833243170781
(1 row)

--- hmm, not so good on that one
select (res).name,(res).len,st_asewkt((res).geom)  from (select find_road_from_to_osm_trigram('AVENUE 116', 'ROAD 264', 'DIAGONAL 254', '06107') as res) a ;

select coalesce ( alternative_route_name_txt,route_id,aadt_cmt) as bleh,aadt_cmt,section_length from hpms where county_code=107 and aadt is not null and aadt > 0 order by random();

 ROAD 152                                  | AVENUE 96 to SHWY 190                               |                 6.06
 TULARE AVE                                | LINWOOD AVE to CHINOWTH RD                          |                 0.25
 CARTMILL AVE                              | SHWY 99 to CL .530 E/SHWY 99                        |                 0.53
 AVE 308                                   | RD 64 to DIAGONAL 68                                |                 0.22
 CORVINA AVE                               | HILLMAN ST to LASPINA ST                            |                  0.3
 201R                                      | TUL-201-13.97/TUL-201-16.01                         |  0.00499999999999901
 DIAGONAL 103                              | .01 MI N AVENUE 248 to ROAD 100                     |                 0.67


select (res).name,(res).len  from (select find_road_from_to_osm_trigram('DIAGONAL 103', 'AVENUE 248','ROAD 100', '06107') as res) a ;g
