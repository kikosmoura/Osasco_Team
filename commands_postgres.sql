


--Create support tables to cross-reference the table resulting from the calculation of Surface Urban Heat with the spatial layers of the municipality of São Paulo
--The vector files for the city of São Paulo were obtained from the website https://geosampa.prefeitura.sp.gov.br/PaginasPublicas/_SBC.aspx


CREATE TABLE stage1_calor.distrito_predios (
    ds_codigo varchar(50),
	concentracao_predios varchar(50) 
);


select * from stage1_calor.distrito_predios

CREATE TABLE stage1_calor.distrito_calor (
ds_codigo varchar(50),
ds_nome varchar(50),
ds_subpref varchar(50),
valor_media_dia real,
valor_media_noite real ,
ds_areamt real ,
ds_areakmt real
);



-- Calculates vegetation cover for each district
drop table if exists stage1_calor.distrito_area_vegetacao_apoio_01; 
create table stage1_calor.distrito_area_vegetacao_apoio_01 
as
select 
ds_codigo,
ds_nome,
ST_Area(ST_Transform(geom, 26986)) as sqm
from stage1_calor.distrito
;;

drop table if exists stage1_calor.distrito_area_vegetacao_apoio_02;
create table stage1_calor.distrito_area_vegetacao_apoio_02
as
SELECT a.ds_codigo,
       a.ds_nome,      
       sum(ST_Area(ST_Transform(ST_Intersection(a.geom, b.geom), 26986))) as sqm
FROM stage1_calor.distrito a, stage1_calor.vegetacao_sp b
WHERE St_intersects(a.geom, b.geom)
and ST_IsValid(a.geom) and ST_IsValid(b.geom)
group by 
a.ds_codigo,
a.ds_nome
;;


drop table if exists stage1_calor.distrito_area_vegetacao_apoio_03;
create table stage1_calor.distrito_area_vegetacao_apoio_03
as
SELECT a.ds_codigo,
       a.ds_nome,      
	   ST_Union(ST_Intersection(a.geom, b.geom)) as sqm
FROM stage1_calor.distrito a, stage1_calor.vegetacao_sp b
WHERE St_intersects(a.geom, b.geom)
--and a.ds_nome = 'MOEMA'
and ST_IsValid(a.geom) and ST_IsValid(b.geom)
group by a.ds_codigo,
       a.ds_nome;
	   
CREATE INDEX geom_distrito_area_vegetacao_apoio_03
  ON stage1_calor.distrito_area_vegetacao_apoio_03
  USING GIST (sqm);;



drop table if exists stage1_calor.distrito_area_vegetacao_final;
create table stage1_calor.distrito_area_vegetacao_final
as
select a.ds_codigo,
       a.ds_nome,
       a.sqm as area_distrito,
	   b.sqm as area_vegetacao,
	   floor((b.sqm / a.sqm) * 100) as perc_area_vegetacao,
--	   c.sqm as geom
from stage1_calor.distrito_area_vegetacao_apoio_01 a
join stage1_calor.distrito_area_vegetacao_apoio_02 b
on a.ds_codigo = b.ds_codigo
join stage1_calor.distrito_area_vegetacao_apoio_03 c
on a.ds_codigo = c.ds_codigo
;;

CREATE INDEX geom_distrito_area_vegetacao_final
  ON stage1_calor.distrito_area_vegetacao_final
  USING GIST (geom);;
;;


drop table if exists stage1_calor.distrito_area_vegetacao_poligonos;
create table stage1_calor.distrito_area_vegetacao_poligonos
as
SELECT a.ds_codigo,
       a.ds_nome,      
	   ST_Intersection(a.geom, b.geom) as geom
FROM stage1_calor.distrito a, stage1_calor.vegetacao_sp b
WHERE St_intersects(a.geom, b.geom)
--and a.ds_nome = 'MOEMA'
and ST_IsValid(a.geom) and ST_IsValid(b.geom)

	   
CREATE INDEX geom_distrito_area_vegetacao_poligonos
  ON stage1_calor.distrito_area_vegetacao_poligonos
  USING GIST (geom);;


delete from stage1_calor.distrito_area_vegetacao_poligonos
where ST_GeometryType(geom) = 'ST_LineString' or ST_GeometryType(geom) = 'ST_MultiPolygon'



drop table if exists stage1_calor.distrito_area_vegetacao_poligonos_v2;
create table stage1_calor.distrito_area_vegetacao_poligonos_v2
as
select
ds_codigo,
ds_nome,
ST_Multi(geom) as geom
from stage1_calor.distrito_area_vegetacao_poligonos
where ST_IsValid(geom);;

CREATE INDEX geom_distrito_area_vegetacao_poligonos_v2
  ON stage1_calor.distrito_area_vegetacao_poligonos_v2
  USING GIST (geom);;


drop table if exists stage1_calor.distrito_predios_final; 
create table stage1_calor.distrito_predios_final
as
select
b.ds_codigo,
a.ds_codigo as ds_nome,
a.concentracao_predios
from stage1_calor.distrito_predios a
join stage1_calor.distrito b
on a.ds_codigo = b.ds_nome
;;

INSERT INTO stage1_calor.distrito_predios_final VALUES
    ('26', 'CONSOLACAO', 'alta');
    
DELETE FROM stage1_calor.distrito_area_vegetacao_final
WHERE ds_codigo = '52';

DELETE FROM stage1_calor.distrito
WHERE ds_codigo = '52';

DELETE FROM stage1_calor.distrito_predios_final
WHERE ds_codigo = '52';

;;

-- Obtains the concentration of tall buildings in a given region based on the number of inhabitants per hectare and the respective area in hectares
select 
ds_nome,
predios
from 
(
	select 
	ds_nome,
	predios,
	qtde,
	ROW_NUMBER() OVER(PARTITION BY ds_nome ORDER BY qtde desc) as indice
	from
	(
		select 
		ds_nome,
		predios,
		count(*) as qtde
		from 
		(
			SELECT a.ds_codigo,
				   a.ds_nome, 
				   b.area_hect,
				   b.habit_hect,
			--	   b.geom,
			CASE 
				  WHEN b.area_hect <= 2.5 and b.habit_hect >= 200  THEN 'alto'
			      WHEN (b.area_hect > 2.5 and b.area_hect <= 7.0) and (b.habit_hect < 200 and habit_hect >= 20 ) THEN 'médio'
				  ELSE 'baixo'
			END as predios
			FROM stage1_calor.distrito a, stage1_calor.densidade_sp b
			WHERE St_intersects(a.geom, b.geom)
--			and a.ds_nome = 'ITAIM BIBI'
			) tmp
		group by
		ds_nome,
		predios
		order by count(*) desc
	) tmp2
) tmp3
where indice=1
order by predios
