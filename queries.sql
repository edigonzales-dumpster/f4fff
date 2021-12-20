DROP TABLE IF EXISTS fff.fruchtfolgeflaechen_buffer_mm;
CREATE TABLE fff.fruchtfolgeflaechen_buffer_mm
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
	(ST_Dump(ST_ReducePrecision(ST_Buffer(geom, 0.02), 0.01))).geom AS geom
FROM 
	fff.fruchtfolgeflaechen_full
;	
CREATE INDEX ON "fff"."fruchtfolgeflaechen_buffer_mm" USING GIST ("geom")
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
		fff.fruchtfolgeflaechen_buffer_mm
) AS foo
;
CREATE INDEX ON "fff"."fruchtfolgeflaechen_exteriorring" USING GIST ("geom")
;

DROP TABLE IF EXISTS fff.fruchtfolgeflaechen_union;
CREATE TABLE fff.fruchtfolgeflaechen_union
AS
SELECT 
	ST_Union(geom, 0.01) AS geom
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

DROP TABLE IF EXISTS fff.polys_point;
CREATE TABLE fff.polys_point 
AS
SELECT 
	geom,
	ST_PointOnSurface(geom) AS point
FROM 
	fff.polys
;
CREATE INDEX ON "fff"."polys_point" USING GIST ("geom")
;

DROP TABLE IF EXISTS fff.polys_attr;
CREATE TABLE fff.polys_attr
AS
SELECT 
	DISTINCT ON (polys.point) 
	gid,
	t_id,
	bezeichnun,
	spezialfal,
	bfs_nr,
	datenstand,
	anrechenba,
	area_aren,
	area_anrec,
	polys.geom AS geometrie
FROM 
	fff.fruchtfolgeflaechen_full AS fff
	INNER JOIN fff.polys_point AS polys 
	ON ST_Intersects(polys.point, fff.geom)
;
CREATE INDEX ON "fff"."polys_attr" USING GIST ("geometrie")
;

DROP TABLE IF EXISTS fff.polys_join;
CREATE TABLE fff.polys_join
AS
SELECT 
	(ST_Dump(geometrie)).geom AS geometrie,
	--	ST_Buffer((ST_Dump(geometrie)).geom, -0.001) AS geometrie,
	fff.t_id,
	bezeichnun,
	spezialfal,
	bfs_nr,
	datenstand,
	anrechenba,
	area_aren,
	area_anrec
FROM 
(
	SELECT 
		t_id, ST_RemoveRepeatedPoints(ST_Union(geometrie)) AS geometrie
	FROM 
		fff.polys_attr
	GROUP BY (t_id)
) AS foo
LEFT JOIN fff.fruchtfolgeflaechen_full AS fff
ON fff.t_id = foo.t_id
;
CREATE INDEX ON "fff"."polys_join" USING GIST ("geometrie")
;


DELETE FROM fff_out.fruchtfolgeflaeche;
INSERT INTO fff_out.fruchtfolgeflaeche 
(
	geometrie,
	bezeichnung,
	spezialfall,
	bfs_nr,
	datenstand,
	anrechenbar,
	area_aren,
	area_anrech
)
SELECT 
	geometrie,
	/*
	CASE 
		WHEN bezeichnun ='bedingt geeignet' THEN 'bedingt_geeignet'
		WHEN bezeichnun = 'geeignete_FFF' THEN 'geeignet'
		WHEN bezeichnun = 'bedingt_geeignete_FFF' THEN 'bedingt_geeignet'
		ELSE bezeichnun 
	END AS bezeichnung,
	*/
	bezeichnun AS bezeichnung,
	/*
	CASE 
		WHEN spezialfal = 'reservezone' THEN 'Reservezone'
		ELSE spezialfal
	END AS spezialfall,
	*/
	spezialfal AS spezialfall,
	bfs_nr,
	to_date(datenstand, 'DD.MM.YYYY') AS datenstand,
	anrechenba AS anrechenbar,
	ST_Area(geometrie) / 100.0 AS area_aren,
	(ST_Area(geometrie) / 100.0)*anrechenba AS area_anrech
FROM 	
	fff.polys_join AS polys 
WHERE 
	ST_Area(geometrie) > 1
;
