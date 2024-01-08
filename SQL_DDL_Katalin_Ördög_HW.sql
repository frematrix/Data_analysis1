CREATE DATABASE mountainclub;

CREATE SCHEMA mountainclub_data;

-- The ORDER OF creating TABLES: I created tables with only primary key, then tables with primary and foreign keys,
-- and then the junction tables.
 
--create table Guide
CREATE TABLE mountainclub_data.guide  (
	Guide_GuidePID varchar(20) NOT NULL,
	Guide_Firstname varchar(30) NOT NULL,
	Guide_Lastname varchar(30) NOT NULL,
	Guide_Date_Of_Birth date NOT NULL,
	Guide_Place_Of_Birth varchar(20) NOT NULL DEFAULT 'London',
	Guide_Phone varchar(20) UNIQUE,
	Guide_Mail varchar(40) UNIQUE,
	Guide_Salary int4 CHECK	(Guide_Salary > 500),
	CONSTRAINT guide_pkey PRIMARY KEY (Guide_GuidePID)
);

-- create table Climber
CREATE TABLE IF NOT EXISTS mountainclub_data.climber (
	Climber_ClimberPID varchar(20) NOT NULL,
	Climber_Firstname varchar(30) NOT NULL,
	Climber_Lastname varchar(30) NOT NULL,
	Climber_Date_Of_Birth date NOT NULL,
	Climber_Place_Of_Birth varchar(20) NOT NULL DEFAULT 'London',
	Climber_Phone varchar(20) UNIQUE,
	Climber_Mail varchar(40) UNIQUE,
	Climber_ICE_Phone varchar(20) NOT NULL,
	Climber_Insurance bool NOT NULL DEFAULT TRUE,
	CONSTRAINT climber_pkey PRIMARY KEY (Climber_ClimberPID)
);

-- create table Program
CREATE TABLE IF NOT EXISTS mountainclub_data.program (
	Program_ProgramID serial4 NOT NULL,
	Program_Type varchar(20) NOT NULL,
	Program_Cost NUMERIC(4,2) CHECK (Program_Cost > 0),
	CONSTRAINT program_pkey PRIMARY KEY (Program_ProgramID)
);

-- create table Accom
CREATE TABLE IF NOT EXISTS mountainclub_data.accom (
	Accom_AccomID serial4 NOT NULL,
	Accom_Type varchar(20) NOT NULL,
	Accom_Cost_Night NUMERIC(4,2) CHECK (Accom_Cost_Night > 0),
	CONSTRAINT accom_pkey PRIMARY KEY (Accom_AccomID)
);

-- create table City
CREATE TABLE IF NOT EXISTS mountainclub_data.city (
	City_ZIP varchar(10) NOT NULL,
	City_Name varchar(20) NOT NULL,
	CONSTRAINT city_pkey PRIMARY KEY (City_ZIP)
);

-- create table Travel
CREATE TABLE IF NOT EXISTS mountainclub_data.travel (
	Travel_TravelID serial4 NOT NULL,
	Travel_Vehicle varchar(10) NOT NULL,
	CONSTRAINT travel_pkey PRIMARY KEY (Travel_TravelID)
);

-- create table Climb
CREATE TABLE IF NOT EXISTS mountainclub_data.climb (
	Climb_ClimbID serial4 NOT NULL,
	Climb_Guide_GuidePID varchar(20) NOT NULL,
	Climb_Name varchar(30) UNIQUE NOT NULL,
	Climb_Length int2 CHECK (Climb_Length > 0),
	Climb_Difficulty int NOT NULL,
	CHECK (Climb_Difficulty BETWEEN 1 AND 10),
	Climb_Registration_Date date CHECK(Climb_Registration_Date > '2000-01-01'),
	Climb_Start date CHECK(Climb_Start > '2000-01-01'),
	Climb_End date CHECK(Climb_Start > '2000-01-01'),
	CHECK (Climb_End >= Climb_Start),
	Climb_Duration int2 GENERATED ALWAYS AS ((Climb_End - Climb_Start) + 1) STORED NOT NULL,
	Climb_Cost NUMERIC(4,2) CHECK (Climb_Cost > 0),
	Climb_Accom_AccomID serial4 NOT NULL,
	CONSTRAINT climb_fkey FOREIGN KEY(Climb_Guide_GuidePID) REFERENCES mountainclub_data.guide (Guide_GuidePID),
	CONSTRAINT accom_fkey FOREIGN KEY(Climb_Accom_AccomID) REFERENCES mountainclub_data.accom (Accom_AccomID)
);

ALTER TABLE mountainclub_data.climb ADD PRIMARY KEY (Climb_ClimbID);

-- create table Event
CREATE TABLE mountainclub_data.event (
	Event_EventID serial4 NOT NULL,
	Event_Guide_GuidePID varchar(20) NOT NULL,
	Event_Place_Name varchar(20) NOT NULL,
	Event_City_City_ZIP varchar(10) NOT NULL,
	Event_Street varchar(20) NOT NULL,
	Event_House_Number int2 NOT NULL,
	Event_Start date CHECK(Event_Start > '2000-01-01'),
	CONSTRAINT event_pkey PRIMARY KEY (Event_EventID),
	CONSTRAINT event_city_fkey FOREIGN KEY(Event_City_City_ZIP) REFERENCES mountainclub_data.city (City_ZIP),
	CONSTRAINT event_guide_fkey FOREIGN KEY(Event_Guide_GuidePID) REFERENCES mountainclub_data.guide (Guide_GuidePID)
);

-- create table Location
CREATE TABLE IF NOT EXISTS mountainclub_data.location (
	Location_LocationID serial4 NOT NULL,
	Location_Travel_TravelID serial4 NOT NULL,
	Location_Country varchar(20) NOT NULL DEFAULT 'United Kingdom',
	Location_City_City_ZIP varchar(10) NOT NULL,
	Location_GPS_Longitude decimal(9,6) NOT NULL,
	Location_GPS_Latitude decimal(8,6) NOT NULL,
	CONSTRAINT location_pkey PRIMARY KEY (Location_LocationID),
	CONSTRAINT location_travel_fkey FOREIGN KEY(Location_Travel_TravelID) REFERENCES mountainclub_data.travel (Travel_TravelID),
	CONSTRAINT location_city_fkey FOREIGN KEY(Location_City_City_ZIP) REFERENCES mountainclub_data.city (City_ZIP)
);

-- create table Mount
CREATE TABLE IF NOT EXISTS mountainclub_data.mount (
	Mount_MountID serial4 NOT NULL,
	Mount_Name varchar(30) UNIQUE NOT NULL,
	Mount_Height int2 CHECK (Mount_Height >= 1000),
	Mount_Location_LocationID serial4 NOT NULL,
	CONSTRAINT mount_pkey PRIMARY KEY (Mount_MountID),
	CONSTRAINT mount_fkey FOREIGN KEY(Mount_Location_LocationID) REFERENCES mountainclub_data.location (Location_LocationID)
);

-- create table Evcl
CREATE TABLE IF NOT EXISTS mountainclub_data.evcl (
	Evcl_EvclID serial4 NOT NULL,
	Evcl_Event_EventID serial4 NOT NULL,
	Evcl_Climber_ClimberPID varchar(20) NOT NULL,
	Evcl_Guest_Nr int2 NOT NULL,
	CONSTRAINT evcl_pkey PRIMARY KEY (Evcl_EvclID),
	CONSTRAINT evcl_event_fkey FOREIGN KEY(Evcl_Event_EventID) REFERENCES mountainclub_data.event (Event_EventID),
	CONSTRAINT evcl_climber_fkey FOREIGN KEY(Evcl_Climber_ClimberPID) REFERENCES mountainclub_data.climber (Climber_ClimberPID)
);

-- create table Clcl
CREATE TABLE IF NOT EXISTS mountainclub_data.clcl (
	Clcl_ClclID serial4 NOT NULL,
	Clcl_Climber_ClimberPID varchar(20) NOT NULL,
	Clcl_Climb_ClimbID serial4 NOT NULL,
	CONSTRAINT clcl_pkey PRIMARY KEY (Clcl_ClclID),
	CONSTRAINT clcl_climber_fkey FOREIGN KEY(Clcl_Climber_ClimberPID) REFERENCES mountainclub_data.climber (Climber_ClimberPID),
	CONSTRAINT clcl_climb_fkey FOREIGN KEY(Clcl_Climb_ClimbID) REFERENCES mountainclub_data.climb (Climb_ClimbID)
);

-- create table Mopr
CREATE TABLE IF NOT EXISTS mountainclub_data.mopr (
	Mopr_MoprID serial4 NOT NULL,
	Mopr_Mount_MountID serial4 NOT NULL,
	Mopr_Program_ProgramID serial4 NOT NULL,
	CONSTRAINT mopr_pkey PRIMARY KEY (Mopr_MoprID),
	CONSTRAINT mopr_mount_fkey FOREIGN KEY(Mopr_Mount_MountID) REFERENCES mountainclub_data.mount (Mount_MountID),
	CONSTRAINT mopr_program_fkey FOREIGN KEY(Mopr_Program_ProgramID) REFERENCES mountainclub_data.program (Program_ProgramID)
);

-- create table Mocl
CREATE TABLE IF NOT EXISTS mountainclub_data.mocl (
	Mocl_MoclID serial4 NOT NULL,
	Mocl_Mount_MountID serial4 NOT NULL,
	Mocl_Climb_ClimbID serial4 NOT NULL,
	CONSTRAINT mocl_pkey PRIMARY KEY (Mocl_MoclID),
	CONSTRAINT mocl_mount_fkey FOREIGN KEY(Mocl_Mount_MountID) REFERENCES mountainclub_data.mount (Mount_MountID),
	CONSTRAINT mocl_climb_fkey FOREIGN KEY(Mocl_Climb_ClimbID) REFERENCES mountainclub_data.climb (Climb_ClimbID)
);

-- I have created the tables, but then I noticed that they were under the wrong schema (public), 
-- so I set the mountainclub_data schema for all the tables. I left here the last table's alter command (mocl).
ALTER TABLE Mocl SET SCHEMA mountainclub_data;

-- To insert new datas in the tables I used INSERT INTO...SELECT statement. I wrapped new values in a temporary table
-- and I used it to join to another tables where there are foreign keys. At the end I used RETURNING clause to get new datas.
INSERT INTO mountainclub_data.guide (guide_guidepid, guide_firstname, guide_lastname, guide_date_of_birth,
			guide_place_of_birth, guide_phone, guide_mail, guide_salary)
SELECT new_guide.guide_guidepid, new_guide.guide_firstname, new_guide.guide_lastname, new_guide.guide_date_of_birth,
			new_guide.guide_place_of_birth, new_guide.guide_phone, new_guide.guide_mail, new_guide.guide_salary
FROM (SELECT 'FA856789432' AS guide_guidepid, 'Henry' AS guide_firstname, 'Tailor' AS guide_lastname, 
			'1974-05-16'::date AS guide_date_of_birth, 'Oxford' AS guide_place_of_birth, '+44 20 6336 1232' AS guide_phone,
			'henry.t@londonmountain.com' AS guide_mail, 3500 AS guide_salary
			UNION ALL
	SELECT 'AS864929412', 'Louis', 'McDonald', '1982-01-21'::date, 'London', '+44 20 5212 5839', 'louis.m@londonmountain.com', 
			3300 AS guide_salary) AS new_guide
WHERE new_guide.guide_guidepid NOT IN (SELECT guide_guidepid FROM mountainclub_data.guide)
RETURNING *;

INSERT INTO mountainclub_data.climber (climber_climberpid, climber_firstname, climber_lastname, 
			climber_date_of_birth, climber_place_of_birth, climber_phone, climber_mail, climber_ice_phone, climber_insurance)
SELECT new_climber.climber_climberpid, new_climber.climber_firstname, new_climber.climber_lastname, 
			new_climber.climber_date_of_birth, new_climber.climber_place_of_birth, new_climber.climber_phone, 
			new_climber.climber_mail, new_climber.climber_ice_phone, new_climber.climber_insurance
FROM (SELECT 'AC234545621' AS climber_climberpid, 'Robert' AS climber_firstname, 'Smith' AS climber_lastname, 
			'1985-04-07'::date AS climber_date_of_birth, 'London' AS climber_place_of_birth, '+44 20 8456 2816' 
			AS climber_phone, 'robert.smith@gmail.com' AS climber_mail, '+44 20 8676 3922' AS climber_ice_phone, 
			FALSE AS climber_insurance
			UNION ALL
	SELECT 'CE739264816', 'Walter', 'Davis', '1972-09-12'::date, 'Bristol', '+44 20 5467 2388', 'walter.dave@gmail.com', 
			'+44 20 2516 2766', TRUE) AS new_climber
WHERE new_climber.climber_climberpid NOT IN (SELECT climber_climberpid FROM mountainclub_data.climber)
RETURNING *;

INSERT INTO mountainclub_data.program (program_type, program_cost)
SELECT new_program.program_type, new_program.program_cost
FROM (SELECT 'Skiing' AS program_type, 37.50 AS program_cost
	UNION ALL
	SELECT 'Bicycle', 12) AS new_program
WHERE new_program.program_type NOT IN (SELECT program_type FROM mountainclub_data.program)
RETURNING *;

INSERT INTO mountainclub_data.accom (accom_type, accom_cost_night)
SELECT new_accom.accom_type, new_accom.accom_cost_night
FROM (SELECT 'Hut (Wales)' AS accom_type, 40.60 AS accom_cost_night
	UNION ALL
	SELECT 'Tent (rent)', 5) AS new_accom
WHERE new_accom.accom_type NOT IN (SELECT accom_type FROM mountainclub_data.accom)
RETURNING *;

INSERT INTO mountainclub_data.travel (travel_vehicle)
SELECT new_travel.travel_vehicle
FROM (SELECT 'airplane' AS travel_vehicle
	UNION ALL
	SELECT 'train') AS new_travel
WHERE new_travel.travel_vehicle NOT IN (SELECT travel_vehicle FROM mountainclub_data.travel)
RETURNING *;

INSERT INTO mountainclub_data.city (city_zip, city_name)
SELECT new_city.city_zip, new_city.city_name
FROM (SELECT 'W1T 1NG' AS city_zip, 'London' AS city_name
	UNION ALL
	SELECT 'BS1 1AD', 'Bristol') AS new_city
WHERE new_city.city_zip NOT IN (SELECT city_zip FROM mountainclub_data.city)
RETURNING *;

INSERT INTO mountainclub_data.city (city_zip, city_name)
SELECT new_city.city_zip, new_city.city_name
FROM (SELECT '44600' AS city_zip, 'Kathmandu' AS city_name) AS new_city
WHERE new_city.city_zip NOT IN (SELECT city_zip FROM mountainclub_data.city)
RETURNING *;
INSERT INTO mountainclub_data.city (city_zip, city_name)
SELECT new_city.city_zip, new_city.city_name
FROM (SELECT '10080' AS city_zip, 'Noasca' AS city_name) AS new_city
WHERE new_city.city_zip NOT IN (SELECT city_zip FROM mountainclub_data.city)
RETURNING *;

ALTER TABLE mountainclub_data.climb 
ALTER COLUMN climb_cost TYPE NUMERIC(6,2);

INSERT INTO mountainclub_data.climb (climb_guide_guidepid, climb_name, climb_length, climb_difficulty,
			climb_registration_date, climb_start, climb_end, climb_cost, climb_accom_accomid)
SELECT g.guide_guidepid, new_climb.climb_name, new_climb.climb_length, new_climb.climb_difficulty,
			new_climb.climb_registration_date, new_climb.climb_start, new_climb.climb_end, new_climb.climb_cost, 
			a.accom_accomid
FROM (SELECT 'henry.t@londonmountain.com' AS climb_guide_mail, 'Everest_Autumn_2023' AS climb_name, 256 AS climb_length,
	7 AS climb_difficulty, '2023-11-07'::date AS climb_registration_date, '2023-11-25'::date AS climb_start, 
	'2023-12-05'::date AS climb_end, 154.50 AS climb_cost, 'Tent (rent)' AS climb_accom_type
	UNION ALL
	SELECT 'louis.m@londonmountain.com' AS climb_guide_mail, 'Gran_Paradiso_Winter_2023' AS climb_name, 345 AS climb_length,
	6 AS climb_difficulty, '2023-12-05'::date AS climb_registration_date, '2023-12-23'::date AS climb_start, 
	'2024-01-02'::date AS climb_end, 152.70 AS climb_cost, 'Tent (rent)' AS climb_accom_type) AS new_climb
INNER JOIN mountainclub_data.guide g 
ON new_climb.climb_guide_mail = guide_mail
INNER JOIN mountainclub_data.accom a
ON new_climb.climb_accom_type = accom_type
WHERE new_climb.climb_name NOT IN (SELECT climb_name FROM mountainclub_data.climb)
RETURNING *;

ALTER TABLE mountainclub_data.event 
ALTER COLUMN event_start TYPE TIMESTAMP WITHOUT TIME ZONE;

INSERT INTO mountainclub_data.EVENT (event_guide_guidepid, event_place_name, event_city_city_zip, event_street,
			event_house_number, event_start)
SELECT g.guide_guidepid, new_event.event_place_name, c.city_zip, new_event.event_street, new_event.event_house_number, 
			new_event.event_start
FROM (SELECT 'louis.m@londonmountain.com' AS event_guide_mail, 'The Audley Public H.' AS event_place_name, 'London'
	AS event_city_name, 'Mount Street' AS event_street, 41 AS event_house_number, '2023-11-20 18:00:00'::timestamp AS event_start
	UNION ALL
	SELECT 'henry.t@londonmountain.com', 'The Lamb Tavern', 'London', 'Leadenhall Market', 12, '2023-11-22 18:30:00'
	::timestamp) AS new_event
INNER JOIN mountainclub_data.guide g
ON new_event.event_guide_mail = guide_mail
INNER JOIN mountainclub_data.city c
ON new_event.event_city_name = city_name
WHERE new_event.event_start NOT IN (SELECT event_start FROM mountainclub_data.event)
RETURNING *;

INSERT INTO mountainclub_data.location (location_travel_travelid, location_country, location_city_city_zip,
			location_gps_longitude, location_gps_latitude)
SELECT t.travel_travelid, new_loc.location_country, c.city_zip, new_loc.location_gps_longitude, 
	new_loc.location_gps_latitude
FROM (SELECT 'airplane' AS location_travel_vehicle, 'Nepal' AS location_country, 'Kathmandu' AS loc_city_name, 
	85.300140 AS location_gps_longitude, 27.700769 AS location_gps_latitude
	UNION ALL 
	SELECT 'train', 'Italy', 'Noasca', 7.317904, 45.452022) AS new_loc
INNER JOIN mountainclub_data.travel t
ON new_loc.location_travel_vehicle = t.travel_vehicle
INNER JOIN mountainclub_data.city c
ON new_loc.loc_city_name = c.city_name
WHERE new_loc.location_gps_longitude NOT IN (SELECT location_gps_longitude FROM mountainclub_data.location)
AND new_loc.location_gps_latitude NOT IN (SELECT location_gps_latitude FROM mountainclub_data.location)
RETURNING *;

INSERT INTO mountainclub_data.mount (mount_name, mount_height, mount_location_locationid)
SELECT new_mount.mount_name, new_mount.mount_height, l.location_locationid
FROM (SELECT 'Gran Paradiso' AS mount_name, 4061 AS mount_height, '10080' AS mount_location_zip
	UNION ALL
	SELECT 'Mount Everest', 8848, '44600') AS new_mount
INNER JOIN mountainclub_data.location l
ON new_mount.mount_location_zip = l.location_city_city_zip
WHERE new_mount.mount_name NOT IN (SELECT mount_name FROM mountainclub_data.mount)
RETURNING *;

INSERT INTO mountainclub_data.evcl (evcl_event_eventid, evcl_climber_climberpid, evcl_guest_nr)
SELECT e.event_eventid, c.climber_climberpid, new_evcl.evcl_guest_nr
FROM (SELECT '2023-11-20 18:00:00'::timestamp AS evcl_event_start, 'robert.smith@gmail.com' AS evcl_climber_mail, 2 AS evcl_guest_nr
	UNION ALL
	SELECT '2023-11-22 18:30:00'::timestamp, 'walter.dave@gmail.com', 1) AS new_evcl
INNER JOIN mountainclub_data.event e
ON new_evcl.evcl_event_start = e.event_start
INNER JOIN mountainclub_data.climber c
ON new_evcl.evcl_climber_mail = c.climber_mail
RETURNING *;

INSERT INTO mountainclub_data.clcl (clcl_climber_climberpid, clcl_climb_climbid)
SELECT clr.climber_climberpid, cl.climb_climbid
FROM (SELECT 'robert.smith@gmail.com' AS clcl_climber_mail, 'Gran_Paradiso_Winter_2023' AS clcl_climb_name
	UNION ALL
	SELECT 'walter.dave@gmail.com', 'Gran_Paradiso_Winter_2023') AS new_clcl
INNER JOIN mountainclub_data.climber clr
ON new_clcl.clcl_climber_mail = clr.climber_mail
INNER JOIN mountainclub_data.climb cl
ON new_clcl.clcl_climb_name = cl.climb_name
RETURNING *;

INSERT INTO mountainclub_data.mopr (mopr_mount_mountid, mopr_program_programid)
SELECT m.mount_mountid, p.program_programid
FROM (SELECT 'Mount Everest' AS mopr_mount_name, 'Skiing' AS mopr_program_type
	UNION ALL
	SELECT 'Gran Paradiso', 'Bicycle') AS new_mopr
INNER JOIN mountainclub_data.mount m
ON new_mopr.mopr_mount_name = m.mount_name
INNER JOIN mountainclub_data.program p
ON new_mopr.mopr_program_type = p.program_type
RETURNING *;

INSERT INTO mountainclub_data.mocl (mocl_mount_mountid, mocl_climb_climbid)
SELECT m.mount_mountid, c.climb_climbid
FROM (SELECT 'Mount Everest' AS mocl_mount_name, 'Everest_Autumn_2023' AS mocl_climb_name
	UNION ALL
	SELECT 'Gran Paradiso', 'Gran_Paradiso_Winter_2023') AS new_mocl
INNER JOIN mountainclub_data.mount m
ON new_mocl.mocl_mount_name = m.mount_name
INNER JOIN mountainclub_data.climb c
ON new_mocl.mocl_climb_name = c.climb_name
RETURNING *;

-- I tried to find any other method to avoid repeated queries, but I only found the "loop" method which solves this task in 
-- one query: https://gist.github.com/kamilakis/59291bd5c77c86756e3877f6be7a8e7a

ALTER TABLE mountainclub_data.accom 
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.city  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.clcl  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.climb  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.climber  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.evcl  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.event
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.guide  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.location
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.mocl  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.mopr  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.mount  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.program
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
ALTER TABLE mountainclub_data.travel  
ADD COLUMN IF NOT EXISTS record_ts timestamp NOT NULL DEFAULT now();
	
