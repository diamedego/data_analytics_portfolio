
-- 1) Crear base de datos y usarla
DROP DATABASE IF EXISTS aerowind;
CREATE DATABASE aerowind;
USE aerowind;

-- 2) Crear tablas crudas (RAW)
-- Nota: las fechas entran como VARCHAR y luego se convierten a DATE.

DROP TABLE IF EXISTS turbinas_raw;
CREATE TABLE turbinas_raw (
    id_turbina VARCHAR(50),
    modelo VARCHAR(100),
    potencia_nominal_kw DECIMAL(10,2),
    ubicacion VARCHAR(150),
    fecha_instalacion VARCHAR(20)  
);

DROP TABLE IF EXISTS clima_raw;
CREATE TABLE clima_raw (
    fecha VARCHAR(20),             
    velocidad_viento_mps DECIMAL(5,1),
    temperatura_c DECIMAL(5,1),
    humedad_relativa_pct DECIMAL(5,1),
    presion_hpa DECIMAL(7,1)
);

DROP TABLE IF EXISTS produccion_raw;
CREATE TABLE produccion_raw (
    id_registro VARCHAR(50),
    id_turbina VARCHAR(50),
    fecha VARCHAR(20),            
    energia_generada_kwh DECIMAL(10,2),
    horas_operativas DECIMAL(5,2),
    horas_inactivas DECIMAL(5,2),
    anio INT,
    temperatura_c DECIMAL(5,2)
);

DROP TABLE IF EXISTS mantenimiento_raw;
CREATE TABLE mantenimiento_raw (
    id_mant VARCHAR(50),
    id_turbina VARCHAR(50),
    fecha_mant VARCHAR(20),        
    tipo_mantenimiento VARCHAR(100),
    duracion_hs DECIMAL(5,2),
    costo_usd DECIMAL(10,2),
    anio INT,
    categoria VARCHAR(200)
);

DROP TABLE IF EXISTS precio_raw;
CREATE TABLE precio_raw (
    id_precio INT,
    fecha VARCHAR(20),             
    precio_kwh_usd DECIMAL(10,5)
);

DROP TABLE IF EXISTS curvas_teoricas_raw;
CREATE TABLE curvas_teoricas_raw (
    modelo VARCHAR(100),
    velocidad_mps INT,
    potencia_teorica_kw INT
);


-- 3) Importación de archivos CSV

-- TURBINAS
LOAD DATA LOCAL INFILE '/Users/diameladego/Desktop/SQL ejercicios/PROYECTO FINAL V4/Bases crudas/turbinas_base_cruda.csv'
INTO TABLE turbinas_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id_turbina, modelo, potencia_nominal_kw, ubicacion, fecha_instalacion);

-- CLIMA
LOAD DATA LOCAL INFILE '/Users/diameladego/Desktop/SQL ejercicios/PROYECTO FINAL V4/Bases crudas/clima_base_cruda.csv'
INTO TABLE clima_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(fecha, velocidad_viento_mps, temperatura_c, humedad_relativa_pct, presion_hpa);

-- PRODUCCIÓN
LOAD DATA LOCAL INFILE '/Users/diameladego/Desktop/SQL ejercicios/PROYECTO FINAL V4/Bases crudas/produccion_base_cruda.csv'
INTO TABLE produccion_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id_registro, id_turbina, fecha, energia_generada_kwh, horas_operativas, horas_inactivas, anio, temperatura_c);

-- MANTENIMIENTO
LOAD DATA LOCAL INFILE '/Users/diameladego/Desktop/SQL ejercicios/PROYECTO FINAL V4/Bases crudas/mantenimiento_base_cruda.csv'
INTO TABLE mantenimiento_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id_mant, id_turbina, fecha_mant, tipo_mantenimiento, duracion_hs, costo_usd, anio, categoria);

-- PRECIO
LOAD DATA LOCAL INFILE 	'/Users/diameladego/Desktop/SQL ejercicios/PROYECTO FINAL V4/Bases crudas/precio_base_cruda.csv'
INTO TABLE precio_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id_precio, fecha, precio_kwh_usd);

-- CURVAS TEÓRICAS
LOAD DATA LOCAL INFILE '/Users/diameladego/Desktop/SQL ejercicios/PROYECTO FINAL V4/Bases crudas/curvas_teoricas_base_cruda.csv'
INTO TABLE curvas_teoricas_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(modelo, velocidad_mps, potencia_teorica_kw);

-- 4) Normalización de fechas

-- Muestreo rápido
SELECT * FROM turbinas_raw LIMIT 10;
SELECT * FROM clima_raw LIMIT 10;
SELECT * FROM produccion_raw LIMIT 10;
SELECT * FROM mantenimiento_raw LIMIT 10;
SELECT * FROM precio_raw LIMIT 10;

-- TURBINAS: fecha_instalacion
SET SQL_SAFE_UPDATES = 0;

UPDATE turbinas_raw
SET fecha_instalacion = DATE_FORMAT(
    STR_TO_DATE(TRIM(fecha_instalacion), '%e/%c/%Y'),
    '%Y-%m-%d'
);

ALTER TABLE turbinas_raw
MODIFY fecha_instalacion DATE;

-- CLIMA: fecha
UPDATE clima_raw
SET fecha = DATE_FORMAT(
    STR_TO_DATE(TRIM(fecha), '%e/%c/%Y'),
    '%Y-%m-%d'
);
    
ALTER TABLE clima_raw
MODIFY fecha DATE;

-- PRODUCCIÓN: fecha , formato correcto.

-- MANTENIMIENTO: fecha_mant, formato correcto.

-- PRECIO: fecha
UPDATE precio_raw
SET fecha = DATE_FORMAT(
    STR_TO_DATE(TRIM(fecha), '%e/%c/%Y'),
    '%Y-%m-%d'
);

ALTER TABLE precio_raw
MODIFY fecha DATE;

-- VERIFICACIONES

-- Rango de fechas
SELECT 'turbinas_raw' AS tabla, MIN(fecha_instalacion) AS fecha_min, MAX(fecha_instalacion) AS fecha_max FROM turbinas_raw
UNION ALL
SELECT 'clima_raw', MIN(fecha), MAX(fecha) FROM clima_raw
UNION ALL
SELECT 'produccion_raw', MIN(fecha), MAX(fecha) FROM produccion_raw
UNION ALL
SELECT 'mantenimiento_raw', MIN(fecha_mant), MAX(fecha_mant) FROM mantenimiento_raw
UNION ALL
SELECT 'precio_raw', MIN(fecha), MAX(fecha) FROM precio_raw;

-- Muestreo rápido
SELECT * FROM turbinas_raw LIMIT 10;
SELECT * FROM clima_raw LIMIT 10;
SELECT * FROM produccion_raw LIMIT 10;
SELECT * FROM mantenimiento_raw LIMIT 10;
SELECT * FROM precio_raw LIMIT 10;


-- 5) Diagnóstico inicial: conteo de filas por tabla

SELECT 'clima_raw' AS tabla, COUNT(*) AS filas FROM clima_raw
UNION ALL
SELECT 'produccion_raw', COUNT(*) FROM produccion_raw
UNION ALL
SELECT 'mantenimiento_raw', COUNT(*) FROM mantenimiento_raw
UNION ALL
SELECT 'turbinas_raw', COUNT(*) FROM turbinas_raw
UNION ALL
SELECT 'precio_raw', COUNT(*) FROM precio_raw
UNION ALL
SELECT 'curvas_teoricas_raw', COUNT(*) FROM curvas_teoricas_raw;

-- 6) Identificacion y limpieza de duplicados

-- TURBINAS: duplicados por id_turbina

SELECT
    id_turbina,
    COUNT(*) AS cantidad_registros
FROM turbinas_raw
GROUP BY id_turbina
HAVING COUNT(*) > 1;

-- No se detectan duplicados en turbinas_raw.

-- CLIMA: duplicados por fecha

SELECT
    fecha,
    COUNT(*) AS cantidad_registros
FROM clima_raw
GROUP BY fecha
HAVING COUNT(*) > 1;

-- No se detectan duplicados en clima_raw.

-- PRODUCCIÓN: duplicados por fecha + turbina

SELECT
    fecha,
    id_turbina,
    COUNT(*) AS cantidad_registros
FROM produccion_raw
GROUP BY fecha, id_turbina
HAVING COUNT(*) > 1;

-- Inspección detallada
SELECT p.*
FROM produccion_raw p
JOIN (
    SELECT fecha, id_turbina
    FROM produccion_raw
    GROUP BY fecha, id_turbina
    HAVING COUNT(*) > 1
) d ON p.fecha = d.fecha AND p.id_turbina = d.id_turbina
ORDER BY p.id_turbina, p.fecha, p.id_registro;

/*
Se detectan registros duplicados para la combinación id_turbina–fecha.
Dado que la información no se encuentra a nivel estrictamente diario,
se procede a unificar los registros con el objetivo de establecer
una granularidad de análisis de un día por turbina.
*/

-- Paso A: consolidación diaria por turbina y fecha

DROP TABLE IF EXISTS produccion_diaria_base;

CREATE TABLE produccion_diaria_base AS
SELECT
    id_turbina,
    fecha,
    SUM(energia_generada_kwh) AS energia_generada_kwh,
    SUM(horas_operativas)     AS horas_operativas,
    SUM(horas_inactivas)      AS horas_inactivas,
    AVG(temperatura_c)        AS temperatura_promedio_c
FROM produccion_raw
GROUP BY
    id_turbina,
    fecha;

-- Paso B: generación del ID diario siguiendo la lógica original
DROP TABLE IF EXISTS produccion_diaria;

CREATE TABLE produccion_diaria AS
SELECT
    CONCAT(
        'P',
        SUBSTRING(id_turbina, 2, 3),
        '_',
        LPAD(
            ROW_NUMBER() OVER (
                PARTITION BY id_turbina
                ORDER BY fecha
            ),
            4,
            '0'
        )
    ) AS id_registro,
    id_turbina,
    fecha,
    YEAR(fecha) AS anio,
    energia_generada_kwh,
    horas_operativas,
    horas_inactivas,
    temperatura_promedio_c
FROM produccion_diaria_base;

-- Validación
SELECT
    fecha,
    id_turbina,
    COUNT(*) AS cantidad_registros
FROM produccion_diaria
GROUP BY fecha, id_turbina
HAVING COUNT(*) > 1;

SELECT 'produccion_diaria', COUNT(*) FROM produccion_diaria;

-- MANTENIMIENTO: duplicados por turbina + fecha

SELECT
    id_turbina,
    fecha_mant,
    COUNT(*) AS cantidad_registros
FROM mantenimiento_raw
GROUP BY id_turbina, fecha_mant
HAVING COUNT(*) > 1;

-- No se detectan duplicados en mantenimiento_raw.

-- PRECIO: duplicados por fecha

SELECT
    fecha,
    COUNT(*) AS cantidad_registros
FROM precio_raw
GROUP BY fecha
HAVING COUNT(*) > 1;

-- No se detectan duplicados en precio_raw.

-- CURVAS TEORICAS: duplicados por modelo y velocidad

SELECT
    modelo,
    velocidad_mps,
    COUNT(*) AS cantidad_registros
FROM curvas_teoricas_raw
GROUP BY modelo, velocidad_mps
HAVING COUNT(*) > 1;

-- No se detectan duplicados en curvas_teoricas_raw

-- 7) Identificacion y limpíeza de valores invalidos

-- TURBINAS
-- a)  Valores nulos o vacíos
SELECT
    SUM(CASE WHEN id_turbina IS NULL OR id_turbina = '' THEN 1 ELSE 0 END) AS id_turbina_faltante,
    SUM(CASE WHEN modelo IS NULL OR modelo = '' THEN 1 ELSE 0 END)         AS modelo_faltante,
    SUM(CASE WHEN potencia_nominal_kw IS NULL THEN 1 ELSE 0 END)           AS potencia_faltante,
    SUM(CASE WHEN ubicacion IS NULL OR ubicacion = '' THEN 1 ELSE 0 END)   AS ubicacion_faltante,
    SUM(CASE WHEN fecha_instalacion IS NULL THEN 1 ELSE 0 END)             AS fecha_faltante
FROM turbinas_raw;

-- No se detectan valores nulos o vacios

-- b) Potencia nominal inválida
-- Potencia nominal invalida
SELECT
    id_turbina,
    modelo,
    potencia_nominal_kw
FROM turbinas_raw
WHERE
    potencia_nominal_kw IS NULL
    OR potencia_nominal_kw <= 0
    OR (modelo = 'Vestas V100' AND potencia_nominal_kw > 2000)
    OR (modelo = 'Vestas V110' AND potencia_nominal_kw > 2200)
    OR (modelo = 'GE.2.5-116'  AND potencia_nominal_kw > 2500);
    
/*
Se detecta potencia negativa.
Conocemos el nombre de turbina y modelo.
Reemplazar por 2000.
*/

UPDATE turbinas_raw
SET potencia_nominal_kw = 2000
WHERE (potencia_nominal_kw IS NULL OR potencia_nominal_kw <= 0)
  AND id_turbina = 'T001'
  AND YEAR(fecha_instalacion) = 2023;

-- c) Fecha de instalación fuera de rango
SELECT *
FROM turbinas_raw
WHERE fecha_instalacion < '2023-01-01'
   OR fecha_instalacion > '2026-01-01';
   
-- No se detectan fechas fuera de rango.

-- CLIMA

-- a) Valores nulos o vacios
SELECT
    SUM(CASE WHEN fecha IS NULL THEN 1 ELSE 0 END)               AS fecha_faltante,
    SUM(CASE WHEN velocidad_viento_mps IS NULL THEN 1 ELSE 0 END) AS viento_faltante,
    SUM(CASE WHEN temperatura_c IS NULL THEN 1 ELSE 0 END)       AS temperatura_faltante,
    SUM(CASE WHEN humedad_relativa_pct IS NULL THEN 1 ELSE 0 END) AS humedad_faltante,
    SUM(CASE WHEN presion_hpa IS NULL THEN 1 ELSE 0 END)          AS presion_faltante
FROM clima_raw;

-- No se detectan valores nulos.

-- b) Temperaturas fuera de rango
SELECT *
FROM clima_raw
WHERE temperatura_c < -20 OR temperatura_c > 60;

-- Eliminar temperaturas imposibles
DELETE FROM clima_raw
WHERE temperatura_c < -20 OR temperatura_c > 60;

-- Se eliminan 3 filas.

-- c) Velocidad del viento inválida
SELECT *
FROM clima_raw
WHERE velocidad_viento_mps IS NULL OR velocidad_viento_mps < 0;

-- No se detecta velocidades negativas.

-- PRODUCCIÓN

-- a) Valores nulos o vacios
SELECT
    SUM(CASE WHEN id_registro IS NULL OR id_registro = '' THEN 1 ELSE 0 END) AS id_faltante,
    SUM(CASE WHEN id_turbina IS NULL OR id_turbina = '' THEN 1 ELSE 0 END)   AS turbina_faltante,
    SUM(CASE WHEN fecha IS NULL THEN 1 ELSE 0 END)                           AS fecha_faltante,
    SUM(CASE WHEN energia_generada_kwh IS NULL THEN 1 ELSE 0 END)            AS energia_faltante,
    SUM(CASE WHEN horas_operativas IS NULL THEN 1 ELSE 0 END)                AS horas_op_faltante,
    SUM(CASE WHEN horas_inactivas IS NULL THEN 1 ELSE 0 END)                 AS horas_inac_faltante,
    SUM(CASE WHEN anio IS NULL THEN 1 ELSE 0 END)                             AS anio_faltante,
    SUM(CASE WHEN temperatura_c IS NULL THEN 1 ELSE 0 END)                   AS temperatura_faltante
FROM produccion_raw;

-- No se detectan valores nulos o vacios.

-- b) Energía o horas inválidas
SELECT *
FROM produccion_raw
WHERE energia_generada_kwh IS NULL OR energia_generada_kwh < 0
   OR horas_operativas IS NULL OR horas_operativas < 0
   OR horas_inactivas IS NULL OR horas_inactivas < 0;

-- No se detectan horas invalidas.

-- c) Validación: energía diaria negativa
SELECT COUNT(*) AS registros_invalidos
FROM produccion_diaria
WHERE energia_generada_kwh < 0;

-- No se detectan valores de energía negativa.

-- d) Validación: horas físicas de operación
SELECT *
FROM produccion_raw
WHERE
    horas_operativas < 0
    OR horas_operativas > 24
    OR horas_inactivas < 0
    OR horas_inactivas > 24
    OR (horas_operativas + horas_inactivas) > 24;

-- No se detectan horas fuera de rango.

-- MANTENIMIENTO

-- a) Valores nulos o vacios 
SELECT
    SUM(CASE WHEN id_mant IS NULL OR id_mant = '' THEN 1 ELSE 0 END) AS id_faltante,
    SUM(CASE WHEN id_turbina IS NULL OR id_turbina = '' THEN 1 ELSE 0 END) AS turbina_faltante,
    SUM(CASE WHEN fecha_mant IS NULL THEN 1 ELSE 0 END)               AS fecha_faltante,
    SUM(CASE WHEN tipo_mantenimiento IS NULL OR tipo_mantenimiento = '' THEN 1 ELSE 0 END) AS tipo_faltante,
    SUM(CASE WHEN duracion_hs IS NULL THEN 1 ELSE 0 END)              AS duracion_faltante,
    SUM(CASE WHEN costo_usd IS NULL THEN 1 ELSE 0 END)                AS costo_faltante,
    SUM(CASE WHEN anio IS NULL THEN 1 ELSE 0 END)                     AS anio_faltante,
    SUM(CASE WHEN categoria IS NULL OR categoria = '' THEN 1 ELSE 0 END) AS categoria_faltante
FROM mantenimiento_raw;

-- b) Verificacion especifica de categoría
SELECT *
FROM mantenimiento_raw
WHERE categoria = '';

/*
Contexto: Cuando se hace preventivo sin falla, no se cargaba ninguna descripción en la columna.
Vamos a reemplazarlo por “Preventivo sin falla” para que no quede vacío.
*/

-- Reemplazo 
UPDATE mantenimiento_raw
SET categoria = 'Preventivo sin falla'
WHERE tipo_mantenimiento = 'Preventivo'
AND (categoria IS NULL OR categoria = '');

-- c) Verificación costos inválidos
SELECT *
FROM mantenimiento_raw
WHERE costo_usd IS NULL
   OR costo_usd < 0;
 
-- Eliminación de costo negativo
DELETE FROM mantenimiento_raw
WHERE costo_usd < 0;

-- d) Verificación horas 0 o NULL de mantenimiento

SELECT *
FROM mantenimiento_raw
WHERE duracion_hs IS NULL
OR duracion_hs = 0;

-- Eliminación
DELETE FROM mantenimiento_raw
WHERE duracion_hs IS NULL
OR duracion_hs = 0;

-- Se elimina una fila.

-- PRECIO

-- a) Valores nulos o vacios 
SELECT
    SUM(CASE WHEN id_precio IS NULL THEN 1 ELSE 0 END) AS id_faltante,
    SUM(CASE WHEN fecha IS NULL THEN 1 ELSE 0 END)     AS fecha_faltante,
    SUM(CASE WHEN precio_kwh_usd IS NULL THEN 1 ELSE 0 END) AS precio_faltante
FROM precio_raw;

-- No se detectan valores nulos o vacios.

-- b) Precio invalido
SELECT *
FROM precio_raw
WHERE precio_kwh_usd IS NULL OR precio_kwh_usd <= 0;

-- Eliminar precio invalido
DELETE FROM precio_raw
WHERE precio_kwh_usd IS NULL
   OR precio_kwh_usd <= 0;
-- Se eliminan dos filas.

-- CURVAS TEÓRICAS

-- a) Valores nulos o vacios
SELECT
    SUM(CASE WHEN modelo IS NULL OR modelo = '' THEN 1 ELSE 0 END) AS modelo_faltante,
    SUM(CASE WHEN velocidad_mps IS NULL THEN 1 ELSE 0 END)         AS velocidad_faltante,
    SUM(CASE WHEN potencia_teorica_kw IS NULL THEN 1 ELSE 0 END)   AS potencia_faltante
FROM curvas_teoricas_raw;

-- No se detectan valores nulos o vacios

-- b) Potencia nominal inválida o velocidades negativas
SELECT *
FROM curvas_teoricas_raw
WHERE velocidad_mps < 0
   OR potencia_teorica_kw < 0;
   
-- No se detectan potencias o velocidades negativas

-- 8) Validaciones cruzadas entre tablas

-- a) Producción con turbina inexistente
SELECT COUNT(*) AS produccion_sin_turbina
FROM produccion_raw p
LEFT JOIN turbinas_raw t ON p.id_turbina = t.id_turbina
WHERE t.id_turbina IS NULL;

-- No se detectan inconsistencias entre tablas.

-- b) Mantenimiento con turbina inexistente
SELECT COUNT(*) AS mantenimiento_sin_turbina
FROM mantenimiento_raw m
LEFT JOIN turbinas_raw t ON m.id_turbina = t.id_turbina
WHERE t.id_turbina IS NULL;

-- Se detecta 1 inconsistencia entre tablas.
SELECT 
    m.*
FROM mantenimiento_raw m
LEFT JOIN turbinas_raw t 
    ON m.id_turbina = t.id_turbina
WHERE t.id_turbina IS NULL;

-- Se detecta id_turbina incorrecto.
-- Eliminación

DELETE m
FROM mantenimiento_raw m
LEFT JOIN turbinas_raw t
    ON m.id_turbina = t.id_turbina
WHERE t.id_turbina IS NULL;

-- c) Producción previa a la fecha de instalación de la turbina
SELECT 
    COUNT(*) AS produccion_pre_instalacion
FROM produccion_raw p
JOIN turbinas_raw t 
    ON p.id_turbina = t.id_turbina
WHERE p.fecha < t.fecha_instalacion;

-- Se detectan 20 inconsistencias.
SELECT 
    p.*
FROM produccion_raw p
JOIN turbinas_raw t 
    ON p.id_turbina = t.id_turbina
WHERE p.fecha < t.fecha_instalacion
ORDER BY p.id_turbina, p.fecha;

-- Se detectan 20 inconsistencias.

-- Eliminación
DELETE p
FROM produccion_raw p
JOIN turbinas_raw t 
    ON p.id_turbina = t.id_turbina
WHERE p.fecha < t.fecha_instalacion;

-- d) Mantenimiento previo a la fecha de instalación de la turbina
SELECT COUNT(*) AS mantenimiento_pre_instalacion
FROM mantenimiento_raw m
JOIN turbinas_raw t ON m.id_turbina = t.id_turbina
WHERE m.fecha_mant < t.fecha_instalacion;

-- No se detectan inconsistencias.

-- f) Clima fuera del rango temporal de producción

SELECT COUNT(*) AS clima_fuera_rango_produccion
FROM clima_raw c
LEFT JOIN produccion_raw p
    ON c.fecha = p.fecha
WHERE p.fecha IS NULL;

-- No se detectan inconsistencias.


-- 9) Crear tablas limpias

DROP TABLE IF EXISTS turbinas;
CREATE TABLE turbinas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_turbina VARCHAR(50) NOT NULL UNIQUE,
    modelo VARCHAR(100),
    potencia_nominal_kw DECIMAL(10,2),
    ubicacion VARCHAR(100),
    fecha_instalacion DATE
);

DROP TABLE IF EXISTS clima;
CREATE TABLE clima (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    velocidad_viento_mps DECIMAL(5,2),
    temperatura_c DECIMAL(5,2),
    humedad_relativa_pct DECIMAL(5,2),
    presion_hpa DECIMAL(7,2)
);

DROP TABLE IF EXISTS produccion;
CREATE TABLE produccion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_registro VARCHAR(50) NOT NULL UNIQUE,
    id_turbina VARCHAR(50) NOT NULL,
    fecha DATE NOT NULL,
    energia_generada_kwh DECIMAL(10,2),
    horas_operativas DECIMAL(5,2),
    horas_inactivas DECIMAL(5,2),
    anio INT,
    temperatura_c DECIMAL(5,2),
    FOREIGN KEY (id_turbina) REFERENCES turbinas(id_turbina)
);

DROP TABLE IF EXISTS mantenimiento;
CREATE TABLE mantenimiento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_mant VARCHAR(50) NOT NULL UNIQUE,
    id_turbina VARCHAR(50) NOT NULL,
    fecha_mant DATE,
    tipo_mantenimiento VARCHAR(100),
    duracion_hs DECIMAL(5,2),
    costo_usd DECIMAL(10,2),
    anio INT,
    categoria VARCHAR(200),
    FOREIGN KEY (id_turbina) REFERENCES turbinas(id_turbina)
);

DROP TABLE IF EXISTS precio;
CREATE TABLE precio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    precio_kwh_usd DECIMAL(10,5) NOT NULL
);

DROP TABLE IF EXISTS curvas_teoricas;
CREATE TABLE curvas_teoricas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    modelo VARCHAR(100) NOT NULL,
    velocidad_mps INT NOT NULL,
    potencia_teorica_kw INT NOT NULL,
    UNIQUE (modelo, velocidad_mps)
);

-- Insertar datos limpios

INSERT INTO turbinas (id_turbina, modelo, potencia_nominal_kw, ubicacion, fecha_instalacion)
SELECT id_turbina, modelo, potencia_nominal_kw, ubicacion, fecha_instalacion
FROM turbinas_raw;

INSERT INTO clima (fecha, velocidad_viento_mps, temperatura_c, humedad_relativa_pct, presion_hpa)
SELECT fecha, velocidad_viento_mps, temperatura_c, humedad_relativa_pct, presion_hpa
FROM clima_raw;

INSERT INTO precio (fecha, precio_kwh_usd)
SELECT fecha, precio_kwh_usd
FROM precio_raw;

INSERT INTO produccion (id_registro, id_turbina, fecha, energia_generada_kwh,
                        horas_operativas, horas_inactivas, anio, temperatura_c)
SELECT p.id_registro, p.id_turbina, p.fecha, p.energia_generada_kwh,
       p.horas_operativas, p.horas_inactivas, p.anio, p.temperatura_promedio_c
FROM produccion_diaria p
JOIN turbinas t ON p.id_turbina = t.id_turbina
WHERE p.energia_generada_kwh <= (t.potencia_nominal_kw * 24)
  AND p.fecha >= t.fecha_instalacion;

INSERT INTO mantenimiento (id_mant, id_turbina, fecha_mant, tipo_mantenimiento,
                           duracion_hs, costo_usd, anio, categoria)
SELECT m.id_mant, m.id_turbina, m.fecha_mant, m.tipo_mantenimiento,
       m.duracion_hs, m.costo_usd, m.anio, m.categoria
FROM mantenimiento_raw m
JOIN turbinas t ON m.id_turbina = t.id_turbina
WHERE m.fecha_mant >= t.fecha_instalacion;

INSERT INTO curvas_teoricas (modelo, velocidad_mps, potencia_teorica_kw)
SELECT modelo, velocidad_mps, potencia_teorica_kw
FROM curvas_teoricas_raw;

-- Verificación final

SELECT 'turbinas' AS tabla, COUNT(*) AS registros FROM turbinas
UNION ALL
SELECT 'clima', COUNT(*) FROM clima
UNION ALL
SELECT 'produccion', COUNT(*) FROM produccion
UNION ALL
SELECT 'mantenimiento', COUNT(*) FROM mantenimiento
UNION ALL
SELECT 'precio', COUNT(*) FROM precio
UNION ALL
SELECT 'curvas_teoricas', COUNT(*) FROM curvas_teoricas;

-- 10)　Descarga de CSV limpios

-- Exportación de tabla turbinas
SELECT *
FROM turbinas
INTO OUTFILE '/Users/Shared/turbinas.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Exportación de tabla clima
SELECT *
FROM clima
INTO OUTFILE '/Users/Shared/clima.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Exportación de tabla produccion
SELECT *
FROM produccion
INTO OUTFILE '/Users/Shared/produccion.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Exportación de tabla mantenimiento
SELECT *
FROM mantenimiento
INTO OUTFILE '/Users/Shared/mantenimiento.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Exportación de tabla precio
SELECT *
FROM precio
INTO OUTFILE '/Users/Shared/precio.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Exportación de tabla curvas_teoricas
SELECT *
FROM curvas_teoricas
INTO OUTFILE '/Users/Shared/curvas_teoricas.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
