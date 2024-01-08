--3. Create a physical database with a separate database and schema and give it an appropriate domain-related name.
CREATE DATABASE fuelstation;

CREATE SCHEMA fueldata;

--create table emp:
CREATE TABLE IF NOT EXISTS fueldata.emp (
	emp_emppid serial4 NOT NULL,
	emp_firstname varchar(30) NOT NULL,	
	emp_lastname varchar(30) NOT NULL,
	emp_fullname text GENERATED ALWAYS AS (emp_firstname || ' ' || emp_lastname) STORED NOT NULL,
	emp_dob date NOT NULL,
	emp_pob varchar(20) NOT NULL,
	emp_phone varchar(20) NOT NULL,
	emp_salary int NOT NULL DEFAULT 2000,
	CONSTRAINT emp_pkey PRIMARY KEY (emp_emppid)
);

ALTER TABLE fueldata.emp 
ADD CONSTRAINT emp_unique UNIQUE (emp_phone);

ALTER TABLE fueldata.emp
ALTER COLUMN emp_emppid TYPE varchar(20);

--create table city:
CREATE TABLE IF NOT EXISTS fueldata.city (
	city_ZIP varchar(10) NOT NULL,
	city_name varchar(20),
	CONSTRAINT city_pkey PRIMARY KEY (city_ZIP)
);

ALTER TABLE fueldata.city
ADD CONSTRAINT not_null_name CHECK (city_name IS NOT NULL);

--create table refill:
CREATE TABLE IF NOT EXISTS fueldata.refill (
	refill_refillID serial4 NOT NULL,
	refill_supplierphone varchar(20) NOT NULL,
	refill_date date NOT NULL,
	CONSTRAINT refill_pkey PRIMARY KEY (refill_refillID)
);

ALTER TABLE fueldata.refill
ADD CONSTRAINT unique_phone UNIQUE (refill_supplierphone);

ALTER TABLE fueldata.refill
DROP CONSTRAINT unique_phone;

ALTER TABLE fueldata.refill
ADD CONSTRAINT check_refill_date CHECK (refill_date > '2023-10-20');

--create table fuel:
CREATE TABLE IF NOT EXISTS fueldata.fuel (
	fuel_fuelID serial4 NOT NULL,
	fuel_name varchar(20),
	fuel_price decimal(5,2),
	CONSTRAINT fuel_pkey PRIMARY KEY (fuel_fuelID)
);

ALTER TABLE fueldata.fuel
ADD CONSTRAINT check_fuelname CHECK (fuel_name IN ('diesel', 'petrol 95', 'petrol 98', 'LPG'));

ALTER TABLE fueldata.fuel
ADD CONSTRAINT check_fuel_positive CHECK (fuel_price>0);

ALTER TABLE fueldata.fuel
ADD COLUMN fuel_last_update timestamptz;

ALTER TABLE fueldata.fuel
ADD CONSTRAINT check_fuel_update CHECK (fuel_last_update IS NOT NULL);

--create table pay:
CREATE TABLE IF NOT EXISTS fueldata.pay (
	pay_payID serial4 NOT NULL,
	pay_amount decimal(9,2) NOT NULL,
	pay_date timestamptz NOT NULL,
	CONSTRAINT pay_pkey PRIMARY KEY (pay_payID)
);

ALTER TABLE fueldata.pay
ADD CONSTRAINT check_pay_date CHECK (pay_date > '2023-10-20 23:59:59'::timestamp);

--create table fac:
CREATE TABLE IF NOT EXISTS fueldata.fac (
	fac_facID serial4 NOT NULL,
	fac_name varchar(30) NOT NULL,
	fac_price decimal(6,2) NOT NULL,
	CONSTRAINT fac_pkey PRIMARY KEY (fac_facID)
);

ALTER TABLE fueldata.fac
ADD CONSTRAINT check_fac_positive CHECK (fac_price>0);

--create table stat:
CREATE TABLE IF NOT EXISTS fueldata.stat (
	stat_statid serial4 NOT NULL,
	stat_name varchar(30) NOT NULL,	
	stat_phone varchar(20) NOT NULL,
	stat_street varchar(20) NOT NULL,
	stat_house_nr int NOT NULL,
	stat_city_ZIP varchar(10) NOT NULL,
	CONSTRAINT stat_pkey PRIMARY KEY (stat_statid),
	CONSTRAINT stat_fkey FOREIGN KEY(stat_city_ZIP) REFERENCES fueldata.city (city_ZIP)
);

--create table pur:
CREATE TABLE IF NOT EXISTS fueldata.pur (
	pur_purid serial4 NOT NULL,
	pur_stat_statid serial4 NOT NULL,	
	pur_fuel_fuelID serial4 NOT NULL,
	pur_pay_payID serial4 NOT NULL,
	pur_quantity decimal(5,2) NOT NULL,
	pur_emp_emppid varchar(20) NOT NULL,
	CONSTRAINT pur_pkey PRIMARY KEY (pur_purid),
	CONSTRAINT pur_fkey FOREIGN KEY(pur_stat_statid) REFERENCES fueldata.stat (stat_statid),
	CONSTRAINT pur_fkey2 FOREIGN KEY(pur_fuel_fuelID) REFERENCES fueldata.fuel (fuel_fuelID),
	CONSTRAINT pur_fkey3 FOREIGN KEY(pur_pay_payID) REFERENCES fueldata.pay (pay_payID),
	CONSTRAINT pur_fkey4 FOREIGN KEY(pur_emp_emppid) REFERENCES fueldata.emp (emp_emppid)
);

ALTER TABLE fueldata.pur
ADD CONSTRAINT check_pur_positive CHECK (pur_quantity>0);

--create table refuel:
CREATE TABLE IF NOT EXISTS fueldata.refuel (
	refuel_refuelid serial4 NOT NULL,
	refuel_refill_refillid serial4 NOT NULL,
	refuel_fuel_fuelid serial4 NOT NULL,	
	refuel_quantity int NOT NULL,
	CONSTRAINT refuel_pkey PRIMARY KEY (refuel_refuelid),
	CONSTRAINT refuel_fkey FOREIGN KEY(refuel_refill_refillid) REFERENCES fueldata.refill (refill_refillid),
	CONSTRAINT refuel_fkey2 FOREIGN KEY(refuel_fuel_fuelid) REFERENCES fueldata.fuel (fuel_fuelID)
);

--create table statfuel:
CREATE TABLE IF NOT EXISTS fueldata.statfuel (
	statfuel_statfuelid serial4 NOT NULL,
	statfuel_fuel_fuelid serial4 NOT NULL,	
	statfuel_stat_statid serial4 NOT NULL,
	statfuel_quantity int NOT NULL,
	CONSTRAINT statfuel_pkey PRIMARY KEY (statfuel_statfuelid),
	CONSTRAINT statfuel_fkey FOREIGN KEY(statfuel_fuel_fuelid) REFERENCES fueldata.fuel (fuel_fuelID),
	CONSTRAINT statfuel_fkey2 FOREIGN KEY(statfuel_stat_statid) REFERENCES fueldata.stat (stat_statid)
);

ALTER TABLE fueldata.statfuel
ADD COLUMN statfuel_last_update timestamptz;

--create table refstat:
CREATE TABLE IF NOT EXISTS fueldata.refstat (
	refstat_refstatid serial4 NOT NULL,
	refstat_refill_refillid serial4 NOT NULL,
	refstat_stat_statid serial4 NOT NULL,
	CONSTRAINT refstat_pkey PRIMARY KEY (refstat_refstatid),
	CONSTRAINT refstat_fkey FOREIGN KEY(refstat_refill_refillid) REFERENCES fueldata.refill (refill_refillid),
	CONSTRAINT refstat_fkey2 FOREIGN KEY(refstat_stat_statid) REFERENCES fueldata.stat (stat_statid)
);

--create table statfac:
CREATE TABLE IF NOT EXISTS fueldata.statfac (
	statfac_statfacid serial4 NOT NULL,
	statfac_stat_statid serial4 NOT NULL,
	statfac_fac_facid serial4 NOT NULL,
	CONSTRAINT statfac_pkey PRIMARY KEY (statfac_statfacid),
	CONSTRAINT statfac_fkey FOREIGN KEY(statfac_stat_statid) REFERENCES fueldata.stat (stat_statid),
	CONSTRAINT statfac_fkey2 FOREIGN KEY(statfac_fac_facid) REFERENCES fueldata.fac (fac_facid)
);

--4. Populate the tables with the sample data generated
INSERT INTO fueldata.emp (emp_emppid, emp_firstname, emp_lastname, emp_dob, emp_pob, emp_phone, emp_salary)
SELECT new_emp.emp_emppid, new_emp.emp_firstname, new_emp.emp_lastname, new_emp.emp_dob, new_emp.emp_pob, 
		new_emp.emp_phone, new_emp.emp_salary
FROM (SELECT 'fa856789432' AS emp_emppid, 'Jilleen' AS emp_firstname, 'Madrell' AS emp_lastname, '1974-05-16'::date AS 
		emp_dob, 'Jinchuan' AS emp_pob, '829-828-6036' AS emp_phone, 2300 AS emp_salary
		UNION ALL
		SELECT '656b06d8fc1', 'Zane', 'Simionato', '1983-02-16'::date, 'Lárdos', '687-247-5580', 2800
		UNION ALL
		SELECT '8fc13ae3b5b', 'Maury', 'Windless', '1965-10-11'::date, 'Portela', '144-468-9228', 2600
		UNION ALL
		SELECT '06d8fc3ae3b', 'Tiebout', 'McGinnell', '1991-09-11'::date, 'Tungawan', '650-437-2370', 2550
		UNION ALL
		SELECT '3b5b4cdcf9', 'Devina', 'Davey', '1976-12-19'::date, 'Zainsk', '980-743-5743', 2350
		UNION ALL
		SELECT 'd8fc13hrlb5b', 'Andeee', 'Mathelon', '1993-04-26'::date, 'Ucluelet', '960-420-0229', 2430
		UNION ALL
		SELECT 'e3b5b4cdd0', 'Lauree', 'Markson', '1989-07-13'::date, 'Citeguh', '178-823-0713', 2800) AS new_emp
WHERE new_emp.emp_phone NOT IN (SELECT emp_phone FROM fueldata.emp)
RETURNING *;

INSERT INTO fueldata.city (city_ZIP, city_name)
SELECT new_city.city_zip, new_city.city_name
FROM (SELECT 'W1T 1NG' AS city_zip, 'London' AS city_name
	UNION ALL
	SELECT 'BS1 1AD', 'Bristol'
	UNION ALL
	SELECT 'B20', 'Birmingham'
	UNION ALL
	SELECT 'G1 1AB', 'Glasgow'
	UNION ALL
	SELECT 'EH1 1AD', 'Edinburgh '
	UNION ALL
	SELECT 'S1 1AA', 'Sheffield '
	UNION ALL
	SELECT 'CH41 5LH', 'Liverpool') AS new_city
WHERE new_city.city_zip NOT IN (SELECT city_zip FROM fueldata.city)
RETURNING *;

INSERT INTO fueldata.refill (refill_supplierphone, refill_date)
SELECT new_refill.refill_supplierphone, new_refill.refill_date
FROM (SELECT '232-898-6694' AS refill_supplierphone, '2023-10-21'::date AS refill_date
	UNION ALL
	SELECT '527-571-5228', '2023-10-21'
	UNION ALL
	SELECT '232-898-6694', '2023-10-23'
	UNION ALL
	SELECT '915-549-6902', '2023-10-23'
	UNION ALL
	SELECT '232-898-6694', '2023-10-24'
	UNION ALL
	SELECT '915-549-6902', '2023-10-24'
	UNION ALL
	SELECT '527-571-5228', '2023-11-02') AS new_refill
RETURNING *;

INSERT INTO fueldata.fuel (fuel_name, fuel_price, fuel_last_update)
SELECT new_fuel.fuel_name, new_fuel.fuel_price, new_fuel.fuel_last_update
FROM (SELECT 'diesel' AS fuel_name, 1.81 AS fuel_price, '2023-10-21 12:39:00'::timestamp AS fuel_last_update
		UNION ALL
		SELECT 'petrol 95', 1.71, '2023-10-21 12:40:00'
		UNION ALL
		SELECT 'petrol 98', 1.74, '2023-10-21 12:41:00'
		UNION ALL
		SELECT 'LPG', 0.91, '2023-10-21 12:42:00'
		UNION ALL
		SELECT 'petrol 95', 1.72, '2023-10-23 16:40:00'
		UNION ALL 
		SELECT 'LPG', 0.94, '2023-10-23 16:42:00'
		UNION ALL
		SELECT 'petrol 98', 1.72, '2023-10-23 16:41:00') AS new_fuel
WHERE new_fuel.fuel_last_update NOT IN (SELECT fuel_last_update FROM fueldata.fuel)
RETURNING *;

INSERT INTO fueldata.pay (pay_amount, pay_date)
SELECT new_pay.pay_amount, new_pay.pay_date
FROM (SELECT 90.5 AS pay_amount, '2023-10-21 13:39:00'::timestamp AS pay_date
		UNION ALL
		SELECT 85.5, '2023-10-21 14:19:15'
		UNION ALL
		SELECT 108.6, '2023-10-21 15:10:40'
		UNION ALL
		SELECT 102.6, '2023-10-21 15:12:05'
		UNION ALL
		SELECT 56.4, '2023-10-23 16:52:00'
		UNION ALL
		SELECT 86, '2023-10-23 16:42:30'
		UNION ALL
		SELECT 37.6, '2023-10-23 16:53:09') AS new_pay
WHERE new_pay.pay_date NOT IN (SELECT pay_date FROM fueldata.pay)
RETURNING *;

INSERT INTO fueldata.fac (fac_name, fac_price)
SELECT new_fac.fac_name, new_fac.fac_price
FROM (SELECT 'manual car wash' AS fac_name, 30.50 AS fac_price
		UNION ALL
		SELECT 'machine car wash standard', 23.45
		UNION ALL
		SELECT 'machine car wash premium', 26.70
		UNION ALL
		SELECT 'windshield repair', 45.60
		UNION ALL
		SELECT 'tire inflation', 12.40
		UNION ALL
		SELECT 'windshield washing', 3.5
		UNION ALL
		SELECT 'tire repair', 25.60) AS new_fac
WHERE new_fac.fac_name NOT IN (SELECT fac_name FROM fueldata.fac)
RETURNING *;

INSERT INTO fueldata.stat (stat_name, stat_phone, stat_street, stat_house_nr, stat_city_ZIP)
SELECT new_stat.stat_name, new_stat.stat_phone, new_stat.stat_street, new_stat.stat_house_nr, c.city_ZIP
FROM (SELECT 'Cohensteer' AS stat_name, '312-598-6253' AS stat_phone, 'Farwell' AS stat_street, 5 AS stat_house_nr,
		'London' AS stat_cityname
		UNION ALL
		SELECT 'Cimpress', '462-291-6597', 'Oriole', 492, 'Bristol'
		UNION ALL
		SELECT 'Blackstone', '316-899-4718', 'North', 741, 'Birmingham'
		UNION ALL
		SELECT 'Ardmore', '887-898-0672', 'Meadow Ridge', 11, 'Glasgow'
		UNION ALL
		SELECT 'Glaukom', '435-316-9715', 'Menomonie', 19, 'Bristol'
		UNION ALL
		SELECT 'Vanguard', '857-966-1231', 'School', 269, 'Glasgow'
		UNION ALL
		SELECT 'Hamilton', '450-249-1520', 'Stone Corner', 149, 'Liverpool') AS new_stat
INNER JOIN fueldata.city c
ON new_stat.stat_cityname = c.city_name 
WHERE new_stat.stat_phone NOT IN (SELECT stat_phone FROM fueldata.stat)
RETURNING *;

INSERT INTO fueldata.pur (pur_stat_statid, pur_fuel_fuelID, pur_pay_payID, pur_quantity, pur_emp_emppid)
SELECT s.stat_statid, f.fuel_fuelID, p.pay_payID, new_pur.pur_quantity, e.emp_emppid
FROM (SELECT 'Cohensteer' AS p_stat_name, '2023-10-21 12:39:00'::timestamp AS p_fuel_update, '2023-10-21 13:39:00'::timestamp AS p_pay_date, 
		50 AS pur_quantity, '829-828-6036' AS p_emp_phone
		UNION ALL
		SELECT 'Cimpress', '2023-10-21 12:40:00', '2023-10-21 14:19:15', 50, '687-247-5580'
		UNION ALL
		SELECT 'Cohensteer', '2023-10-21 12:39:00', '2023-10-21 15:10:40', 60, '829-828-6036'
		UNION ALL
		SELECT 'Cimpress', '2023-10-21 12:40:00', '2023-10-21 15:12:05', 60, '687-247-5580'
		UNION ALL
		SELECT 'Vanguard', '2023-10-23 16:42:00', '2023-10-23 16:52:00', 60, '178-823-0713'
		UNION ALL
		SELECT 'Vanguard', '2023-10-23 16:41:00', '2023-10-23 16:42:30', 50, '178-823-0713'
		UNION ALL
		SELECT 'Hamilton', '2023-10-23 16:42:00', '2023-10-23 16:53:09', 40, '960-420-0229') AS new_pur
INNER JOIN fueldata.stat s
ON new_pur.p_stat_name = s.stat_name
INNER JOIN fueldata.fuel f
ON new_pur.p_fuel_update = f.fuel_last_update
INNER JOIN fueldata.pay p
ON new_pur.p_pay_date = p.pay_date 
INNER JOIN fueldata.emp e
ON new_pur.p_emp_phone = e.emp_phone
RETURNING *;

INSERT INTO fueldata.refuel (refuel_refill_refillid, refuel_fuel_fuelid, refuel_quantity)
SELECT r.refill_refillid, f.fuel_fuelid, new_refuel.refuel_quantity
FROM (SELECT '2023-10-21'::date AS rf_refill_date, '2023-10-21 12:39:00'::timestamp AS rf_fuel_update, 1000 AS refuel_quantity
		UNION ALL
		SELECT '2023-10-21', '2023-10-21 12:40:00', 1200
		UNION ALL
		SELECT '2023-10-21', '2023-10-21 12:41:00', 1500
		UNION ALL
		SELECT '2023-10-21', '2023-10-21 12:42:00', 1300
		UNION ALL
		SELECT '2023-10-23', '2023-10-23 16:40:00', 1250
		UNION ALL
		SELECT '2023-10-23', '2023-10-23 16:42:00', 1350
		UNION ALL
		SELECT '2023-10-23', '2023-10-23 16:41:00', 1150) AS new_refuel
INNER JOIN fueldata.refill r
ON new_refuel.rf_refill_date = r.refill_date 
INNER JOIN fueldata.fuel f
ON new_refuel.rf_fuel_update = f.fuel_last_update
RETURNING *;

INSERT INTO fueldata.statfuel (statfuel_fuel_fuelid, statfuel_stat_statid, statfuel_quantity, statfuel_last_update)
SELECT f.fuel_fuelid, s.stat_statid, new_statfuel.statfuel_quantity, new_statfuel.statfuel_last_update
FROM (SELECT '2023-10-21 12:39:00'::timestamp AS sf_fuel_update, 'Cohensteer' AS sf_stat_name, 500 AS statfuel_quantity,
		'2023-10-21 16:39:00'::timestamp AS statfuel_last_update
		UNION ALL
		SELECT '2023-10-21 12:40:00', 'Cimpress', 400, '2023-10-21 16:40:00'
		UNION ALL
		SELECT '2023-10-21 12:41:00', 'Blackstone', 500, '2023-10-21 16:41:00'
		UNION ALL
		SELECT '2023-10-21 12:42:00', 'Ardmore', 600, '2023-10-21 16:42:00'
		UNION ALL
		SELECT '2023-10-23 16:40:00', 'Blackstone', 850, '2023-10-23 18:40:00'
		UNION ALL
		SELECT '2023-10-23 16:42:00', 'Cimpress', 650, '2023-10-23 18:42:00'
		UNION ALL
		SELECT '2023-10-23 16:41:00', 'Glaukom', 750, '2023-10-23 18:41:00') AS new_statfuel
INNER JOIN fueldata.fuel f
ON new_statfuel.sf_fuel_update = f.fuel_last_update
INNER JOIN fueldata.stat s
ON new_statfuel.sf_stat_name = s.stat_name
RETURNING *;

INSERT INTO fueldata.refstat (refstat_refill_refillid, refstat_stat_statid)
SELECT r.refill_refillid, s.stat_statid
FROM (SELECT '2023-10-21'::date AS rs_refill_date, 'Cohensteer' AS rs_stat_name
		UNION ALL
		SELECT '2023-10-21', 'Cimpress'
		UNION ALL
		SELECT '2023-10-21', 'Blackstone'
		UNION ALL
		SELECT '2023-10-21', 'Ardmore'
		UNION ALL
		SELECT '2023-10-23', 'Blackstone'
		UNION ALL
		SELECT '2023-10-23', 'Cimpress'
		UNION ALL
		SELECT '2023-10-23', 'Glaukom') AS new_refstat
INNER JOIN fueldata.refill r
ON new_refstat.rs_refill_date = r.refill_date 
INNER JOIN fueldata.stat s
ON new_refstat.rs_stat_name = s.stat_name 
RETURNING *;

INSERT INTO fueldata.statfac (statfac_stat_statid, statfac_fac_facid)
SELECT s.stat_statid, f.fac_facid
FROM (SELECT 'Cohensteer' AS sf_stat_name, 'manual car wash' AS sf_fac_name
		UNION ALL
		SELECT 'Cohensteer', 'windshield repair'
		UNION ALL
		SELECT 'Ardmore', 'manual car wash'
		UNION ALL
		SELECT 'Ardmore', 'tire inflation'
		UNION ALL
		SELECT 'Ardmore', 'tire repair'
		UNION ALL
		SELECT 'Blackstone', 'manual car wash'
		UNION ALL
		SELECT 'Glaukom', 'tire inflation') AS new_statfac
INNER JOIN fueldata.stat s
ON new_statfac.sf_stat_name = s.stat_name 
INNER JOIN fueldata.fac f
ON new_statfac.sf_fac_name = f.fac_name
RETURNING *;

--5.1 Create a function that updates data in one of your tables.
SELECT update_fac_row(1, 'car polish', 25.00);

CREATE OR REPLACE FUNCTION update_fac_row(
    p_facID integer,
    p_fac_name varchar(30),
    p_fac_price decimal(6,2)
)
RETURNS VOID AS $$
BEGIN
    UPDATE fueldata.fac
    SET 
        fac_name = p_fac_name,
        fac_price = p_fac_price
    WHERE
        fac_facID = p_facID;
END;
$$ LANGUAGE plpgsql;

--5.2 Create a function that adds a new transaction to your transaction table. 
SELECT add_transaction(100.50, '2023-11-15 14:30:00'::timestamptz);

CREATE OR REPLACE FUNCTION add_transaction(
    p_amount decimal(9,2),
    p_date timestamptz
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO fueldata.pay (pay_amount, pay_date)
    VALUES (p_amount, p_date);

    RAISE NOTICE 'Transaction successfully added.';
END;
$$ LANGUAGE plpgsql;

--6. Create a view that presents analytics for the most recently added quarter in your database. 
SELECT * FROM fueldata.sales_summary;

CREATE OR REPLACE VIEW fueldata.sales_summary AS
SELECT
    st.stat_name,
    COALESCE(SUM(sf.statfuel_quantity * f.fuel_price), 0) AS sales
FROM fueldata.stat st
LEFT JOIN fueldata.statfuel sf ON st.stat_statid = sf.statfuel_stat_statid
LEFT JOIN fueldata.fuel f ON sf.statfuel_fuel_fuelid = f.fuel_fuelid
LEFT JOIN fueldata.pur p ON p.pur_fuel_fuelid = f.fuel_fuelid 
LEFT JOIN fueldata.pay pa ON pa.pay_payid = p.pur_pay_payid 
WHERE EXTRACT(QUARTER FROM pa.pay_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
GROUP BY st.stat_name;

--7. Create a read-only role for the manager. This role should have permission to perform SELECT queries on the database 
-- tables, and also be able to log in.
CREATE ROLE manager LOGIN PASSWORD 'managerpw';

GRANT CONNECT ON DATABASE fuelstation TO manager;

GRANT USAGE ON SCHEMA fueldata TO manager;

GRANT SELECT ON ALL TABLES IN SCHEMA fueldata TO manager;

SET ROLE manager;

SELECT * FROM fuelstation.fueldata.city c;


