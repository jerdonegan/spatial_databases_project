--Check Tables
SELECT * FROM blueflag;
SELECT * FROM waw_road;
SELECT * FROM county;

--Creates table of Beaches within 3km of the Wild Atlantic Way
DROP TABLE IF EXISTS waw_bf;
CREATE TABLE waw_bf AS
SELECT DISTINCT bf.id, bf.geom, bf."BEACH", bf."2014" AS blueFlag
FROM blueflag AS bf, waw_road AS waw 
WHERE
ST_DWithin(
  ST_Transform(waw.geom, 29902),
  ST_Transform(bf.geom, 29902),3000)
ORDER BY bf.id;

--Creates table of Beaches within 3km of the Wild Atlantic Way
--This query uses st_buffer from week 12 lectures and returns same resulta as above query.
DROP TABLE IF EXISTS waw_bf_12;
CREATE TABLE waw_bf_12 AS
SELECT DISTINCT bf.id, bf.geom, bf."BEACH", bf."2014" AS blueFlag
FROM blueflag AS bf, waw_road AS waw 
WHERE
ST_Contains(
	ST_Buffer(ST_Transform(waw.geom, 29902),3000), 
    ST_Transform(bf.geom, 29902))
ORDER BY bf.id;

SELECT * FROM waw_bf_12;

--Create New Counties table with only relevent data
DROP TABLE IF EXISTS counties;
CREATE TABLE Counties AS
(SELECT id, geom, name_tag AS name 
FROM County);

--Add columns to Counties.
ALTER TABLE Counties ADD COLUMN Beaches INTEGER DEFAULT 0;
ALTER TABLE Counties ADD COLUMN BlueFlag2014 INTEGER DEFAULT 0;
ALTER TABLE Counties ADD COLUMN NoBlueFlag2014 INTEGER DEFAULT 0;

SELECT name, beaches, BlueFlag2014, NOBlueFlag2014 FROM Counties;

--Fill in Number of beaches on WAW for Each County
WITH TableSubQuery AS(
    SELECT count(*) AS NumBeaches, co.name
    FROM Counties AS co, waw_bf AS bf
    --ST_Contains does not work due to geoms for most of the beaches being outside the county polygon
    --Using ST_DWithin instead
    WHERE ST_DWithin(
  		ST_Transform(co.geom, 29902),
  		ST_Transform(bf.geom, 29902),500)
    GROUP BY co.name
)
UPDATE Counties 
SET beaches = TableSubQuery.NumBeaches
FROM TableSubquery 
WHERE Counties.name = TableSubQuery.name;

--Fill in Number of Blue Flag beaches on WAW for Each County
WITH TableSubQuery AS(
    SELECT count(*) AS NumBeaches, co.name
    FROM Counties AS co, waw_bf AS bf
    --WHERE ST_Contains(co.geom, bf.geom)
    --ST_Contains does not work due to geoms for most of the beaches being outside the county polygon
    --Using ST_DWithin instead
    WHERE ST_DWithin(
  		ST_Transform(co.geom, 29902),
  		ST_Transform(bf.geom, 29902),500)
    AND bf."2014" = 1
    GROUP BY co.name
)
UPDATE Counties 
SET BlueFlag2014 = TableSubQuery.NumBeaches
FROM TableSubquery 
WHERE Counties.name = TableSubQuery.name;

--Fill in Number of Non Blue Flag beaches on WAW for Each County
--Not used in maps, just used for visual check of values
WITH TableSubQuery AS(
    SELECT count(*) AS NumBeaches, co.name
    FROM Counties AS co, waw_bf AS bf
    WHERE ST_DWithin(
  		ST_Transform(co.geom, 29902),
  		ST_Transform(bf.geom, 29902),500)
    AND bf."2014" = 0
    GROUP BY co.name
)
UPDATE Counties 
SET NoBlueFlag2014 = TableSubQuery.NumBeaches
FROM TableSubquery 
WHERE Counties.name = TableSubQuery.name;

SELECT name, beaches, BlueFlag2014, NOBlueFlag2014 FROM Counties;


--Create a view of the Wild Atlantic Way as points
DROP VIEW IF EXISTS waw_road_points;
CREATE VIEW waw_road_points AS
SELECT DISTINCT id, ST_Line_Interpolate_Point(geom,.5) AS geom FROM waw_road;
