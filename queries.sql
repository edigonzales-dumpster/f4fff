/*
CREATE TABLE fff.fruchtfolgeflaechen_mm
AS
SELECT 
	gid,
	t_id,
	bezeichnun,
	spezialfal,
	bfs_nr,
	datenstand,
	anrechenba,
	area_aren,
	area_anrec,
	(ST_Dump(ST_ReducePrecision(geom, 0.001))).geom AS geom
FROM 
	fff.fruchtfolgeflaechen_partial
;	
CREATE INDEX ON "fff"."fruchtfolgeflaechen_mm" USING GIST ("geom")
;

DROP TABLE IF EXISTS fff.fruchtfolgeflaechen_exteriorring;
CREATE TABLE fff.fruchtfolgeflaechen_exteriorring
AS 
SELECT 
	ST_ExteriorRing(geom) AS geom
FROM 
(
	SELECT 
		(ST_DumpRings(geom)).geom AS geom
	FROM 
		fff.fruchtfolgeflaechen_mm
) AS foo
;
CREATE INDEX ON "fff"."fruchtfolgeflaechen_exteriorring" USING GIST ("geom")
;
*/

DROP TABLE IF EXISTS fff.fruchtfolgeflaechen_union;
CREATE TABLE fff.fruchtfolgeflaechen_union
AS
SELECT 
	ST_Union(geom) AS geom
FROM 
	fff.fruchtfolgeflaechen_exteriorring
;
CREATE INDEX ON "fff"."fruchtfolgeflaechen_union" USING GIST ("geom")
;

DROP SEQUENCE IF EXISTS polyseq;
CREATE SEQUENCE polyseq;
DROP TABLE IF EXISTS fff.polys;
CREATE TABLE fff.polys 
AS
SELECT 
	nextval('polyseq') AS id, 
	(ST_Dump(ST_Polygonize(geom))).geom AS geom
FROM 
	fff.fruchtfolgeflaechen_union
;
CREATE INDEX ON "fff"."polys" USING GIST ("geom")
;

