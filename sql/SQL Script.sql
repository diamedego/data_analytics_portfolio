-- 1) Create database 
DROP DATABASE IF EXISTS aerowind;
CREATE DATABASE aerowind;
USE aerowind;

-- 2) Create raw tables
-- Note: dates are loaded as VARCHAR and then converted to DATE.

DROP TABLE IF EXISTS turbines_raw;
CREATE TABLE turbines_raw (
    turbine_id VARCHAR(50),
    model VARCHAR(100),
    nominal_power_kw DECIMAL(10,2),
    location VARCHAR(150),
    installation_date VARCHAR(20)
);

DROP TABLE IF EXISTS weather_raw;
CREATE TABLE weather_raw (
    date VARCHAR(20),
    wind_speed_mps DECIMAL(5,1),
    temperature_c DECIMAL(5,1),
    relative_humidity_pct DECIMAL(5,1),
    pressure_hpa DECIMAL(7,1)
);

DROP TABLE IF EXISTS production_raw;
CREATE TABLE production_raw (
    record_id VARCHAR(50),
    turbine_id VARCHAR(50),
    date VARCHAR(20),
    generated_energy_kwh DECIMAL(10,2),
    operating_hours DECIMAL(5,2),
    inactive_hours DECIMAL(5,2),
    year INT,
    temperature_c DECIMAL(5,2)
);

DROP TABLE IF EXISTS maintenance_raw;
CREATE TABLE maintenance_raw (
    maintenance_id VARCHAR(50),
    turbine_id VARCHAR(50),
    maintenance_date VARCHAR(20),
    maintenance_type VARCHAR(100),
    duration_hs DECIMAL(5,2),
    cost_usd DECIMAL(10,2),
    year INT,
    category VARCHAR(200)
);

DROP TABLE IF EXISTS price_raw;
CREATE TABLE price_raw (
    price_id INT,
    date VARCHAR(20),
    price_kwh_usd DECIMAL(10,5)
);

DROP TABLE IF EXISTS theoretical_curves_raw;
CREATE TABLE theoretical_curves_raw (
    model VARCHAR(100),
    speed_mps INT,
    theoretical_power_kw INT
);


-- 3) CSV file import
-- Update the paths below to match your local directory before running.

-- TURBINES
LOAD DATA LOCAL INFILE '/your/local/path/turbinas_base_cruda.csv'
INTO TABLE turbines_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(turbine_id, model, nominal_power_kw, location, installation_date);

-- WEATHER
LOAD DATA LOCAL INFILE '/your/local/path/clima_base_cruda.csv'
INTO TABLE weather_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(date, wind_speed_mps, temperature_c, relative_humidity_pct, pressure_hpa);

-- PRODUCTION
LOAD DATA LOCAL INFILE '/your/local/path/produccion_base_cruda.csv'
INTO TABLE production_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(record_id, turbine_id, date, generated_energy_kwh, operating_hours, inactive_hours, year, temperature_c);

-- MAINTENANCE
LOAD DATA LOCAL INFILE '/your/local/path/mantenimiento_base_cruda.csv'
INTO TABLE maintenance_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(maintenance_id, turbine_id, maintenance_date, maintenance_type, duration_hs, cost_usd, year, category);

-- PRICE
LOAD DATA LOCAL INFILE '/your/local/path/precio_base_cruda.csv'
INTO TABLE price_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(price_id, date, price_kwh_usd);

-- THEORETICAL CURVES
LOAD DATA LOCAL INFILE '/your/local/path/curvas_teoricas_base_cruda.csv'
INTO TABLE theoretical_curves_raw
CHARACTER SET utf8
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(model, speed_mps, theoretical_power_kw);

-- 4) Date normalization

-- Quick sample
SELECT * FROM turbines_raw LIMIT 10;
SELECT * FROM weather_raw LIMIT 10;
SELECT * FROM production_raw LIMIT 10;
SELECT * FROM maintenance_raw LIMIT 10;
SELECT * FROM price_raw LIMIT 10;

-- TURBINES: installation_date
SET SQL_SAFE_UPDATES = 0;

UPDATE turbines_raw
SET installation_date = DATE_FORMAT(
    STR_TO_DATE(TRIM(installation_date), '%e/%c/%Y'),
    '%Y-%m-%d'
);

ALTER TABLE turbines_raw
MODIFY installation_date DATE;

-- WEATHER: date
UPDATE weather_raw
SET date = DATE_FORMAT(
    STR_TO_DATE(TRIM(date), '%e/%c/%Y'),
    '%Y-%m-%d'
);

ALTER TABLE weather_raw
MODIFY date DATE;

-- PRODUCTION: date, correct format.

-- MAINTENANCE: maintenance_date, correct format.

-- PRICE: date
UPDATE price_raw
SET date = DATE_FORMAT(
    STR_TO_DATE(TRIM(date), '%e/%c/%Y'),
    '%Y-%m-%d'
);

ALTER TABLE price_raw
MODIFY date DATE;

-- VERIFICATIONS

-- Date range
SELECT 'turbines_raw' AS table_name, MIN(installation_date) AS date_min, MAX(installation_date) AS date_max FROM turbines_raw
UNION ALL
SELECT 'weather_raw', MIN(date), MAX(date) FROM weather_raw
UNION ALL
SELECT 'production_raw', MIN(date), MAX(date) FROM production_raw
UNION ALL
SELECT 'maintenance_raw', MIN(maintenance_date), MAX(maintenance_date) FROM maintenance_raw
UNION ALL
SELECT 'price_raw', MIN(date), MAX(date) FROM price_raw;

-- Quick sample
SELECT * FROM turbines_raw LIMIT 10;
SELECT * FROM weather_raw LIMIT 10;
SELECT * FROM production_raw LIMIT 10;
SELECT * FROM maintenance_raw LIMIT 10;
SELECT * FROM price_raw LIMIT 10;


-- 5) Initial diagnosis: row count per table

SELECT 'weather_raw' AS table_name, COUNT(*) AS rows FROM weather_raw
UNION ALL
SELECT 'production_raw', COUNT(*) FROM production_raw
UNION ALL
SELECT 'maintenance_raw', COUNT(*) FROM maintenance_raw
UNION ALL
SELECT 'turbines_raw', COUNT(*) FROM turbines_raw
UNION ALL
SELECT 'price_raw', COUNT(*) FROM price_raw
UNION ALL
SELECT 'theoretical_curves_raw', COUNT(*) FROM theoretical_curves_raw;

-- 6) Duplicate identification and removal

-- TURBINES: duplicates by turbine_id

SELECT
    turbine_id,
    COUNT(*) AS record_count
FROM turbines_raw
GROUP BY turbine_id
HAVING COUNT(*) > 1;

-- No duplicates detected in turbines_raw.

-- WEATHER: duplicates by date

SELECT
    date,
    COUNT(*) AS record_count
FROM weather_raw
GROUP BY date
HAVING COUNT(*) > 1;

-- No duplicates detected in weather_raw.

-- PRODUCTION: duplicates by date + turbine_id

SELECT
    date,
    turbine_id,
    COUNT(*) AS record_count
FROM production_raw
GROUP BY date, turbine_id
HAVING COUNT(*) > 1;

-- Detailed inspection
SELECT p.*
FROM production_raw p
JOIN (
    SELECT date, turbine_id
    FROM production_raw
    GROUP BY date, turbine_id
    HAVING COUNT(*) > 1
) d ON p.date = d.date AND p.turbine_id = d.turbine_id
ORDER BY p.turbine_id, p.date, p.record_id;

/* Duplicate records are detected for the turbine_id–date combination. Records are consolidated to achieve a daily granularity of one record per turbine per day. */

-- Step A: daily consolidation by turbine and date

DROP TABLE IF EXISTS daily_production_base;

CREATE TABLE daily_production_base AS
SELECT
    turbine_id,
    date,
    SUM(generated_energy_kwh) AS generated_energy_kwh,
    SUM(operating_hours)      AS operating_hours,
    SUM(inactive_hours)       AS inactive_hours,
    AVG(temperature_c)        AS avg_temperature_c
FROM production_raw
GROUP BY
    turbine_id,
    date;

-- Step B: ID generation following the original logic
DROP TABLE IF EXISTS daily_production;

CREATE TABLE daily_production AS
SELECT
    CONCAT(
        'P',
        SUBSTRING(turbine_id, 2, 3),
        '_',
        LPAD(
            ROW_NUMBER() OVER (
                PARTITION BY turbine_id
                ORDER BY date
            ),
            4,
            '0'
        )
    ) AS record_id,
    turbine_id,
    date,
    YEAR(date) AS year,
    generated_energy_kwh,
    operating_hours,
    inactive_hours,
    avg_temperature_c
FROM daily_production_base;

-- Validation
SELECT
    date,
    turbine_id,
    COUNT(*) AS record_count
FROM daily_production
GROUP BY date, turbine_id
HAVING COUNT(*) > 1;

SELECT 'daily_production', COUNT(*) FROM daily_production;

-- Drop intermediate table
DROP TABLE IF EXISTS daily_production_base;

-- MAINTENANCE: duplicates by turbine_id + date

SELECT
    turbine_id,
    maintenance_date,
    COUNT(*) AS record_count
FROM maintenance_raw
GROUP BY turbine_id, maintenance_date
HAVING COUNT(*) > 1;

-- No duplicates detected in maintenance_raw.

-- PRICE: duplicates by date

SELECT
    date,
    COUNT(*) AS record_count
FROM price_raw
GROUP BY date
HAVING COUNT(*) > 1;

-- No duplicates detected in price_raw.

-- THEORETICAL CURVES: duplicates by model and speed

SELECT
    model,
    speed_mps,
    COUNT(*) AS record_count
FROM theoretical_curves_raw
GROUP BY model, speed_mps
HAVING COUNT(*) > 1;

-- No duplicates detected in theoretical_curves_raw.

-- 7) Invalid value identification and removal

-- TURBINES
-- a) Null or empty values
SELECT
    SUM(CASE WHEN turbine_id IS NULL OR turbine_id = '' THEN 1 ELSE 0 END)       AS turbine_id_missing,
    SUM(CASE WHEN model IS NULL OR model = '' THEN 1 ELSE 0 END)                  AS model_missing,
    SUM(CASE WHEN nominal_power_kw IS NULL THEN 1 ELSE 0 END)                     AS nominal_power_missing,
    SUM(CASE WHEN location IS NULL OR location = '' THEN 1 ELSE 0 END)            AS location_missing,
    SUM(CASE WHEN installation_date IS NULL THEN 1 ELSE 0 END)                    AS installation_date_missing
FROM turbines_raw;

-- No null or empty values detected.

-- b) Invalid nominal power
SELECT
    turbine_id,
    model,
    nominal_power_kw
FROM turbines_raw
WHERE
    nominal_power_kw IS NULL
    OR nominal_power_kw <= 0
    OR (model = 'Vestas V100' AND nominal_power_kw > 2000)
    OR (model = 'Vestas V110' AND nominal_power_kw > 2200)
    OR (model = 'GE.2.5-116'  AND nominal_power_kw > 2500);

/*
A negative power value is detected.
The turbine name and model are known.
Replace with 2000.
*/

UPDATE turbines_raw
SET nominal_power_kw = 2000
WHERE (nominal_power_kw IS NULL OR nominal_power_kw <= 0)
  AND turbine_id = 'T001'
  AND YEAR(installation_date) = 2023;

-- c) Installation date out of range
SELECT *
FROM turbines_raw
WHERE installation_date < '2023-01-01'
   OR installation_date > '2026-01-01';

-- No out-of-range dates detected.

-- WEATHER

-- a) Null or empty values
SELECT
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END)                     AS date_missing,
    SUM(CASE WHEN wind_speed_mps IS NULL THEN 1 ELSE 0 END)           AS wind_speed_missing,
    SUM(CASE WHEN temperature_c IS NULL THEN 1 ELSE 0 END)            AS temperature_missing,
    SUM(CASE WHEN relative_humidity_pct IS NULL THEN 1 ELSE 0 END)    AS humidity_missing,
    SUM(CASE WHEN pressure_hpa IS NULL THEN 1 ELSE 0 END)             AS pressure_missing
FROM weather_raw;

-- No null values detected.

-- b) Temperatures out of range
SELECT *
FROM weather_raw
WHERE temperature_c < -20 OR temperature_c > 60;

-- Delete impossible temperatures
DELETE FROM weather_raw
WHERE temperature_c < -20 OR temperature_c > 60;

-- 3 rows deleted.

-- c) Invalid wind speed
SELECT *
FROM weather_raw
WHERE wind_speed_mps IS NULL OR wind_speed_mps < 0;

-- No negative wind speeds detected.

-- PRODUCTION

-- a) Null or empty values
SELECT
    SUM(CASE WHEN record_id IS NULL OR record_id = '' THEN 1 ELSE 0 END)          AS record_id_missing,
    SUM(CASE WHEN turbine_id IS NULL OR turbine_id = '' THEN 1 ELSE 0 END)        AS turbine_id_missing,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END)                                 AS date_missing,
    SUM(CASE WHEN generated_energy_kwh IS NULL THEN 1 ELSE 0 END)                 AS energy_missing,
    SUM(CASE WHEN operating_hours IS NULL THEN 1 ELSE 0 END)                      AS operating_hours_missing,
    SUM(CASE WHEN inactive_hours IS NULL THEN 1 ELSE 0 END)                       AS inactive_hours_missing,
    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END)                                 AS year_missing,
    SUM(CASE WHEN temperature_c IS NULL THEN 1 ELSE 0 END)                        AS temperature_missing
FROM production_raw;

-- No null or empty values detected.

-- b) Invalid energy or hours
SELECT *
FROM production_raw
WHERE generated_energy_kwh IS NULL OR generated_energy_kwh < 0
   OR operating_hours IS NULL OR operating_hours < 0
   OR inactive_hours IS NULL OR inactive_hours < 0;

-- No invalid hours detected.

-- c) Validation: negative daily energy
SELECT COUNT(*) AS invalid_records
FROM daily_production
WHERE generated_energy_kwh < 0;

-- No negative energy values detected.

-- d) Validation: physical operating hours
SELECT *
FROM production_raw
WHERE
    operating_hours < 0
    OR operating_hours > 24
    OR inactive_hours < 0
    OR inactive_hours > 24
    OR (operating_hours + inactive_hours) > 24;

-- No out-of-range hours detected.

-- MAINTENANCE

-- a) Null or empty values
SELECT
    SUM(CASE WHEN maintenance_id IS NULL OR maintenance_id = '' THEN 1 ELSE 0 END)      AS maintenance_id_missing,
    SUM(CASE WHEN turbine_id IS NULL OR turbine_id = '' THEN 1 ELSE 0 END)              AS turbine_id_missing,
    SUM(CASE WHEN maintenance_date IS NULL THEN 1 ELSE 0 END)                           AS maintenance_date_missing,
    SUM(CASE WHEN maintenance_type IS NULL OR maintenance_type = '' THEN 1 ELSE 0 END)  AS maintenance_type_missing,
    SUM(CASE WHEN duration_hs IS NULL THEN 1 ELSE 0 END)                                AS duration_missing,
    SUM(CASE WHEN cost_usd IS NULL THEN 1 ELSE 0 END)                                   AS cost_missing,
    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END)                                       AS year_missing,
    SUM(CASE WHEN category IS NULL OR category = '' THEN 1 ELSE 0 END)                  AS category_missing
FROM maintenance_raw;

-- b) Specific verification: empty category values
SELECT *
FROM maintenance_raw
WHERE category = '';

/* Context: When preventive maintenance was performed without failure, no description was loaded in the column. It will be replaced with "Preventive without failure" so the field is not left empty. */

-- Replacement
UPDATE maintenance_raw
SET category = 'Preventive without failure'
WHERE maintenance_type = 'Preventive'
AND (category IS NULL OR category = '');

-- c) Invalid cost verification
SELECT *
FROM maintenance_raw
WHERE cost_usd IS NULL
   OR cost_usd < 0;

-- Delete negative cost
DELETE FROM maintenance_raw
WHERE cost_usd < 0;

-- d) Verification of null or zero maintenance hours
SELECT *
FROM maintenance_raw
WHERE duration_hs IS NULL
   OR duration_hs = 0;

-- Deletion
DELETE FROM maintenance_raw
WHERE duration_hs IS NULL
   OR duration_hs = 0;

-- One row deleted.

-- PRICE

-- a) Null or empty values
SELECT
    SUM(CASE WHEN price_id IS NULL THEN 1 ELSE 0 END)        AS price_id_missing,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END)            AS date_missing,
    SUM(CASE WHEN price_kwh_usd IS NULL THEN 1 ELSE 0 END)   AS price_missing
FROM price_raw;

-- No null or empty values detected.

-- b) Invalid price
SELECT *
FROM price_raw
WHERE price_kwh_usd IS NULL OR price_kwh_usd <= 0;

-- Delete invalid price
DELETE FROM price_raw
WHERE price_kwh_usd IS NULL
   OR price_kwh_usd <= 0;
-- Two rows deleted.

-- THEORETICAL CURVES

-- a) Null or empty values
SELECT
    SUM(CASE WHEN model IS NULL OR model = '' THEN 1 ELSE 0 END)          AS model_missing,
    SUM(CASE WHEN speed_mps IS NULL THEN 1 ELSE 0 END)                    AS speed_missing,
    SUM(CASE WHEN theoretical_power_kw IS NULL THEN 1 ELSE 0 END)         AS theoretical_power_missing
FROM theoretical_curves_raw;

-- No null or empty values detected.

-- b) Invalid nominal power or negative speeds
SELECT *
FROM theoretical_curves_raw
WHERE speed_mps < 0
   OR theoretical_power_kw < 0;

-- No negative power or speed values detected.

-- 8) Cross-table validations

-- a) Production with non-existent turbine
SELECT COUNT(*) AS production_without_turbine
FROM production_raw p
LEFT JOIN turbines_raw t ON p.turbine_id = t.turbine_id
WHERE t.turbine_id IS NULL;

-- No inconsistencies detected between tables.

-- b) Maintenance with non-existent turbine
SELECT COUNT(*) AS maintenance_without_turbine
FROM maintenance_raw m
LEFT JOIN turbines_raw t ON m.turbine_id = t.turbine_id
WHERE t.turbine_id IS NULL;

-- 1 inconsistency detected between tables.
SELECT
    m.*
FROM maintenance_raw m
LEFT JOIN turbines_raw t
    ON m.turbine_id = t.turbine_id
WHERE t.turbine_id IS NULL;

-- Incorrect turbine_id detected.
-- Deletion

DELETE m
FROM maintenance_raw m
LEFT JOIN turbines_raw t
    ON m.turbine_id = t.turbine_id
WHERE t.turbine_id IS NULL;

-- c) Production prior to turbine installation date
SELECT
    COUNT(*) AS production_pre_installation
FROM production_raw p
JOIN turbines_raw t
    ON p.turbine_id = t.turbine_id
WHERE p.date < t.installation_date;

-- 20 inconsistencies detected.
SELECT
    p.*
FROM production_raw p
JOIN turbines_raw t
    ON p.turbine_id = t.turbine_id
WHERE p.date < t.installation_date
ORDER BY p.turbine_id, p.date;

-- 20 inconsistencies detected.

-- Deletion
DELETE p
FROM production_raw p
JOIN turbines_raw t
    ON p.turbine_id = t.turbine_id
WHERE p.date < t.installation_date;

-- d) Maintenance prior to turbine installation date
SELECT COUNT(*) AS maintenance_pre_installation
FROM maintenance_raw m
JOIN turbines_raw t ON m.turbine_id = t.turbine_id
WHERE m.maintenance_date < t.installation_date;

-- No inconsistencies detected.

-- e) Weather data outside the production temporal range
SELECT COUNT(*) AS weather_out_of_production_range
FROM weather_raw w
LEFT JOIN production_raw p
    ON w.date = p.date
WHERE p.date IS NULL;

-- No inconsistencies detected.

SET SQL_SAFE_UPDATES = 1;


-- 9) Create clean tables

DROP TABLE IF EXISTS Turbines;
CREATE TABLE Turbines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    turbine_id VARCHAR(50) NOT NULL UNIQUE,
    model VARCHAR(100),
    nominal_power_kw DECIMAL(10,2),
    location VARCHAR(100),
    installation_date DATE
);

DROP TABLE IF EXISTS Weather;
CREATE TABLE Weather (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    wind_speed_mps DECIMAL(5,2),
    temperature_c DECIMAL(5,2),
    relative_humidity_pct DECIMAL(5,2),
    pressure_hpa DECIMAL(7,2)
);

DROP TABLE IF EXISTS Production;
CREATE TABLE Production (
    id INT AUTO_INCREMENT PRIMARY KEY,
    record_id VARCHAR(50) NOT NULL UNIQUE,
    turbine_id VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    generated_energy_kwh DECIMAL(10,2),
    operating_hours DECIMAL(5,2),
    inactive_hours DECIMAL(5,2),
    year INT,
    temperature_c DECIMAL(5,2),
    FOREIGN KEY (turbine_id) REFERENCES Turbines(turbine_id)
);

DROP TABLE IF EXISTS Maintenance;
CREATE TABLE Maintenance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    maintenance_id VARCHAR(50) NOT NULL UNIQUE,
    turbine_id VARCHAR(50) NOT NULL,
    maintenance_date DATE,
    maintenance_type VARCHAR(100),
    duration_hs DECIMAL(5,2),
    cost_usd DECIMAL(10,2),
    year INT,
    category VARCHAR(200),
    FOREIGN KEY (turbine_id) REFERENCES Turbines(turbine_id)
);

DROP TABLE IF EXISTS Price;
CREATE TABLE Price (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    price_kwh_usd DECIMAL(10,5) NOT NULL
);

DROP TABLE IF EXISTS Theoretical_curves;
CREATE TABLE Theoretical_curves (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(100) NOT NULL,
    speed_mps INT NOT NULL,
    theoretical_power_kw INT NOT NULL,
    UNIQUE (model, speed_mps)
);

-- Insert clean data

INSERT INTO Turbines (turbine_id, model, nominal_power_kw, location, installation_date)
SELECT turbine_id, model, nominal_power_kw, location, installation_date
FROM turbines_raw;

INSERT INTO Weather (date, wind_speed_mps, temperature_c, relative_humidity_pct, pressure_hpa)
SELECT date, wind_speed_mps, temperature_c, relative_humidity_pct, pressure_hpa
FROM weather_raw;

INSERT INTO Price (date, price_kwh_usd)
SELECT date, price_kwh_usd
FROM price_raw;

INSERT INTO Production (record_id, turbine_id, date, generated_energy_kwh,
                        operating_hours, inactive_hours, year, temperature_c)
SELECT p.record_id, p.turbine_id, p.date, p.generated_energy_kwh,
       p.operating_hours, p.inactive_hours, p.year, p.avg_temperature_c
FROM daily_production p
JOIN Turbines t ON p.turbine_id = t.turbine_id
WHERE p.generated_energy_kwh <= (t.nominal_power_kw * 24)
  AND p.date >= t.installation_date;

INSERT INTO Maintenance (maintenance_id, turbine_id, maintenance_date, maintenance_type,
                         duration_hs, cost_usd, year, category)
SELECT m.maintenance_id, m.turbine_id, m.maintenance_date, m.maintenance_type,
       m.duration_hs, m.cost_usd, m.year, m.category
FROM maintenance_raw m
JOIN Turbines t ON m.turbine_id = t.turbine_id
WHERE m.maintenance_date >= t.installation_date;

INSERT INTO Theoretical_curves (model, speed_mps, theoretical_power_kw)
SELECT model, speed_mps, theoretical_power_kw
FROM theoretical_curves_raw;

-- Final verification

SELECT 'Turbines' AS table_name, COUNT(*) AS records FROM Turbines
UNION ALL
SELECT 'Weather', COUNT(*) FROM Weather
UNION ALL
SELECT 'Production', COUNT(*) FROM Production
UNION ALL
SELECT 'Maintenance', COUNT(*) FROM Maintenance
UNION ALL
SELECT 'Price', COUNT(*) FROM Price
UNION ALL
SELECT 'Theoretical_curves', COUNT(*) FROM Theoretical_curves;

-- 10) Clean CSV export
-- Update the paths below to match your local directory before running.

-- Export Turbines table
SELECT *
FROM Turbines
INTO OUTFILE '/your/local/path/Turbines.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Export Weather table
SELECT *
FROM Weather
INTO OUTFILE '/your/local/path/Weather.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Export Production table
SELECT *
FROM Production
INTO OUTFILE '/your/local/path/Production.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Export Maintenance table
SELECT *
FROM Maintenance
INTO OUTFILE '/your/local/path/Maintenance.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Export Price table
SELECT *
FROM Price
INTO OUTFILE '/your/local/path/Price.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Export Theoretical_curves table
SELECT *
FROM Theoretical_curves
INTO OUTFILE '/your/local/path/Theoretical_curves.csv'
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- 11) Drop raw and intermediate tables

DROP TABLE IF EXISTS turbines_raw;
DROP TABLE IF EXISTS weather_raw;
DROP TABLE IF EXISTS production_raw;
DROP TABLE IF EXISTS maintenance_raw;
DROP TABLE IF EXISTS price_raw;
DROP TABLE IF EXISTS theoretical_curves_raw;
DROP TABLE IF EXISTS daily_production;
