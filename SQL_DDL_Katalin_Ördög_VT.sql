CREATE DATABASE hospitaldb;

CREATE SCHEMA hospital_data;

CREATE TABLE IF NOT EXISTS hospital_data.hospital (
	hospital_hospitalid serial4 NOT NULL,
	hospital_name varchar(50) NOT NULL,
	hospital_contact_phone varchar(20) UNIQUE,
	hospital_district int2 CHECK (hospital_district > 0 AND hospital_district < 23),
	hospital_recorddate timestamp NOT NULL DEFAULT now(),
	CONSTRAINT hospital_pkey PRIMARY KEY (hospital_hospitalid)
);

CREATE TABLE IF NOT EXISTS hospital_data.patient (
	patient_patientid serial4 NOT NULL,
	patient_firstname varchar(20) NOT NULL,	
	patient_lastname varchar(20) NOT NULL,
	patient_fullname text GENERATED ALWAYS AS (patient_firstname || ' ' || patient_lastname) STORED NOT NULL,
	patient_dob date NOT NULL,
	patient_phone varchar(20) UNIQUE,
	patient_recorddate timestamp NOT NULL DEFAULT now(),
	CONSTRAINT patient_pkey PRIMARY KEY (patient_patientid)
);

CREATE TABLE IF NOT EXISTS hospital_data.medicine (
	medicine_medicineid serial4 NOT NULL,
	medicine_name varchar(20) NOT NULL,
	medicine_recorddate timestamp NOT NULL DEFAULT now(),
	CONSTRAINT medicine_pkey PRIMARY KEY (medicine_medicineid)
);

CREATE TABLE IF NOT EXISTS hospital_data.service (
	service_serviceid serial4 NOT NULL,
	service_name varchar(30) NOT NULL DEFAULT 'Labor',
	service_hospital_hospitalid serial4 NOT NULL,
	service_recorddate timestamp NOT NULL DEFAULT now(),
	CONSTRAINT service_pkey PRIMARY KEY (service_serviceid),
	CONSTRAINT service_fkey FOREIGN KEY(service_hospital_hospitalid) REFERENCES hospital_data.hospital (hospital_hospitalid)
);

CREATE TABLE IF NOT EXISTS hospital_data.doctor (
	doctor_doctorid serial4 NOT NULL,
	doctor_firstname varchar(20) NOT NULL,	
	doctor_lastname varchar(20) NOT NULL,
	doctor_fullname text GENERATED ALWAYS AS (doctor_firstname || ' ' || doctor_lastname) STORED NOT NULL,
	doctor_phone varchar(20) UNIQUE,
	doctor_specialization varchar(30) NOT NULL,
	doctor_hospital_hospitalid serial4 NOT NULL,
	doctor_recorddate timestamp NOT NULL DEFAULT now(),
	CONSTRAINT doctor_pkey PRIMARY KEY (doctor_doctorid),
	CONSTRAINT doctor_fkey FOREIGN KEY(doctor_hospital_hospitalid) REFERENCES hospital_data.hospital (hospital_hospitalid)
);

CREATE TABLE IF NOT EXISTS hospital_data.appointment (
	appointment_appointmentid serial4 NOT NULL,
	appointment_hospital_hospitalid serial4 NOT NULL,
	appointment_doctor_doctorid serial4 NOT NULL,
	appointment_service_serviceid serial4 NOT NULL,
	appointment_patient_patientid serial4 NOT NULL,
	appointment_start timestamp NOT NULL,
	appointment_recorddate timestamp NOT NULL DEFAULT now(),
	CONSTRAINT appointment_pkey PRIMARY KEY (appointment_appointmentid),
	CONSTRAINT appointment_fkey FOREIGN KEY(appointment_hospital_hospitalid) REFERENCES hospital_data.hospital (hospital_hospitalid),
	CONSTRAINT appointment_fkey2 FOREIGN KEY(appointment_doctor_doctorid) REFERENCES hospital_data.doctor (doctor_doctorid),
	CONSTRAINT appointment_fkey3 FOREIGN KEY(appointment_service_serviceid) REFERENCES hospital_data.service (service_serviceid),
	CONSTRAINT appointment_fkey4 FOREIGN KEY(appointment_patient_patientid) REFERENCES hospital_data.patient (patient_patientid)
);

CREATE TABLE IF NOT EXISTS hospital_data.treatment (
	treatment_treatmentid serial4 NOT NULL,
	treatment_appointment_appointmentid serial4 NOT NULL,
	treatment_notes TEXT DEFAULT 'No further treatment is required',
	treatment_recorddate timestamp NOT NULL DEFAULT now(),
	CONSTRAINT treatment_pkey PRIMARY KEY (treatment_treatmentid),
	CONSTRAINT treatment_fkey FOREIGN KEY(treatment_appointment_appointmentid) REFERENCES hospital_data.appointment (appointment_appointmentid)
);

CREATE TABLE IF NOT EXISTS hospital_data.treatmedi (
	treatmedi_treatmediid serial4 NOT NULL,
	treatmedi_treatment_treatmentid serial4 NOT NULL,
	treatmedi_medicine_medicineid serial4 NOT NULL,
	treatmedi_quantity int2 NOT NULL,
	treatmedi_dosagedesc TEXT DEFAULT '1 per day',
	treatmedi_recorddate timestamp NOT NULL DEFAULT now(),
	CONSTRAINT treatmedi_pkey PRIMARY KEY (treatmedi_treatmediid),
	CONSTRAINT treatmedi_fkey FOREIGN KEY(treatmedi_treatment_treatmentid) REFERENCES hospital_data.treatment (treatment_treatmentid),
	CONSTRAINT treatmedi_fkey2 FOREIGN KEY(treatmedi_medicine_medicineid) REFERENCES hospital_data.medicine (medicine_medicineid)
);

INSERT INTO hospital_data.hospital (hospital_name, hospital_contact_phone, hospital_district, hospital_recorddate)
SELECT new_hosp.hospital_name, new_hosp.hospital_contact_phone, new_hosp.hospital_district, new_hosp.hospital_recorddate
FROM (SELECT 'Hospital District 1' AS hospital_name, '+86 885 186 1224' AS hospital_contact_phone, 1 AS hospital_district, 
			'2023-07-19 18:16:00'::timestamp AS hospital_recorddate
	UNION ALL
	SELECT 'Hospital District 2', '+30 180 143 0219', 2, '2023-08-16 21:16:00'::timestamp
	UNION ALL
	SELECT 'Hospital District 3', '+30 180 632 0219', 3, '2023-09-02 15:34:00'::timestamp
	UNION ALL
	SELECT 'Hospital District 4', '+351 872 727 5814', 4, '2023-08-21 16:19:00'::timestamp
	UNION ALL
	SELECT 'Hospital District 7', '+86 779 218 5257', 7, '2023-09-11 17:29:00'::timestamp
	UNION ALL
	SELECT 'Hospital District 15', '+62 890 180 1324', 15, '2023-10-21 08:49:00'::timestamp
	UNION ALL
	SELECT 'Hospital District 19', '+7 817 383 5404', 19, '2023-10-23 09:23:00'::timestamp) AS new_hosp
WHERE new_hosp.hospital_name NOT IN (SELECT hospital_name FROM hospital_data.hospital)
RETURNING *;

INSERT INTO hospital_data.patient (patient_firstname, patient_lastname, patient_dob, patient_phone, patient_recorddate)
SELECT new_pat.patient_firstname, new_pat.patient_lastname, new_pat.patient_dob, new_pat.patient_phone, new_pat.patient_recorddate
FROM (SELECT 'Jilleen' AS patient_firstname, 'Madrell' AS patient_lastname, '1974-05-16'::date AS patient_dob, 
		'+351 872 727 5814' AS patient_phone, '2023-08-10 12:16:00'::timestamp AS patient_recorddate
	UNION ALL
	SELECT 'Zane', 'Simionato', '1983-02-16'::date, '+46 966 292 5642', '2023-08-16 21:18:00'::timestamp
	UNION ALL
	SELECT 'Maury', 'Windless', '1965-10-11'::date, '+86 277 632 5713', '2023-09-14 09:11:00'::timestamp
	UNION ALL
	SELECT 'Tiebout', 'McGinnell', '1991-09-11'::date, '+46 966 292 4637', '2023-08-20 10:54:00'::timestamp
	UNION ALL
	SELECT 'Devina', 'Davey', '1976-12-19'::date, '+93 637 292 5631', '2023-10-23 15:19:00'::timestamp
	UNION ALL
	SELECT 'Andeee', 'Mathelon', '1993-04-26'::date, '+46 966 292 8473', '2023-09-30 16:27:00'::timestamp
	UNION ALL
	SELECT 'Lauree', 'Markson', '1989-07-13'::date, '+28 966 378 5633', '2023-09-19 23:17:00'::timestamp) AS new_pat
WHERE new_pat.patient_phone NOT IN (SELECT patient_phone FROM hospital_data.patient)
RETURNING *;

INSERT INTO hospital_data.medicine (medicine_name, medicine_recorddate)
SELECT new_medi.medicine_name, new_medi.medicine_recorddate
FROM (SELECT 'pravastatin' AS medicine_name, '2023-09-26 16:13:00'::timestamp AS medicine_recorddate
	UNION ALL
	SELECT 'Moisture Renew', '2023-08-31 07:24:00'::timestamp
	UNION ALL
	SELECT 'Aspirin', '2023-09-24 09:22:00'::timestamp
	UNION ALL
	SELECT 'RISPERIDONE', '2023-09-12 08:12:00'::timestamp
	UNION ALL
	SELECT 'Heparin', '2023-10-21 15:45:00'::timestamp
	UNION ALL
	SELECT 'Saridon', '2023-09-23 11:12:00'::timestamp
	UNION ALL
	SELECT 	'Desmopressin', '2023-10-03 18:38:00'::timestamp) AS new_medi
WHERE new_medi.medicine_name NOT IN (SELECT medicine_name FROM hospital_data.medicine)
RETURNING *;

INSERT INTO hospital_data.service (service_name, service_hospital_hospitalid, service_recorddate)
SELECT new_serv.service_name, h.hospital_hospitalid, new_serv.service_recorddate
FROM (SELECT 'pediatrics' AS service_name, 'Hospital District 2' AS serv_hospital_name, '2023-10-03 18:38:00'::timestamp 
	AS service_recorddate
	UNION ALL
	SELECT 'endocrinology', 'Hospital District 2', '2023-09-12 08:21:00'--
	UNION ALL
	SELECT 'urology', 'Hospital District 3', '2023-09-23 07:31:00'
	UNION ALL
	SELECT 'gynecology', 'Hospital District 3', '2023-08-28 11:34:00'
	UNION ALL
	SELECT 'radiology', 'Hospital District 2', '2023-09-12 08:21:00'
	UNION ALL
	SELECT 'genetics', 'Hospital District 15', '2023-10-18 12:29:00'
	UNION ALL
	SELECT 'diabetes', 'Hospital District 7', '2023-08-19 16:29:00') AS new_serv
INNER JOIN hospital_data.hospital h
ON new_serv.serv_hospital_name = h.hospital_name 
WHERE new_serv.service_name NOT IN (SELECT service_name FROM hospital_data.service)
RETURNING *;

INSERT INTO hospital_data.doctor (doctor_firstname, doctor_lastname, doctor_phone, doctor_specialization, 
			doctor_hospital_hospitalid, doctor_recorddate)
SELECT new_doc.doctor_firstname, new_doc.doctor_lastname, new_doc.doctor_phone, new_doc.doctor_specialization,
			h.hospital_hospitalid, new_doc.doctor_recorddate
FROM (SELECT 'Susanna' AS doctor_firstname, 'Tooher' AS doctor_lastname, '+380 310 837 2035' AS doctor_phone, 
			'radiologist' AS doctor_specialization, 'Hospital District 2' AS doc_hospital_name, 
			'2023-08-06 12:39:00'::timestamp AS doctor_recorddate
	UNION ALL
	SELECT 'Dalton', 'Michel', '+380 310 396 2031', 'radiologist', 'Hospital District 2', '2023-08-13 09:41:00'
	UNION ALL
	SELECT 'Janelle', 'Peregrine', '+380 310 396 2045', 'urologist', 'Hospital District 3', '2023-09-19 17:31:00'
	UNION ALL
	SELECT 'Charlene', 'Carlo', '+380 310 396 2037', 'gynecologist', 'Hospital District 3', '2023-10-17 19:34:00'
	UNION ALL
	SELECT 'Sebastian', 'Pruckner', '+380 310 396 3728', 'radiologist', 'Hospital District 2', '2023-10-17 07:29:00'
	UNION ALL
	SELECT 'Orbadiah', 'Bedboro', '+380 310 396 3845', 'geneticist', 'Hospital District 15', '2023-09-28 18:29:00'
	UNION ALL
	SELECT 'Talya', 'Groucutt', '+380 310 396 3823', 'diabetic', 'Hospital District 7', '2023-08-11 14:19:00') AS new_doc
INNER JOIN hospital_data.hospital h
ON new_doc.doc_hospital_name = h.hospital_name 
WHERE new_doc.doctor_phone NOT IN (SELECT doctor_phone FROM hospital_data.doctor)
RETURNING *;

INSERT INTO hospital_data.appointment (appointment_hospital_hospitalid, appointment_doctor_doctorid, appointment_service_serviceid,
			appointment_patient_patientid, appointment_start, appointment_recorddate)
SELECT h.hospital_hospitalid, d.doctor_doctorid, s.service_serviceid, p.patient_patientid, new_app.appointment_start,
			new_app.appointment_recorddate
FROM (SELECT 'Hospital District 2' AS app_hospital_name, '+380 310 837 2035' AS app_doctor_phone, 'pediatrics' AS app_service_name,
			'+351 872 727 5814' AS app_patient_phone, '2023-08-21 14:13:00'::timestamp AS appointment_start, '2023-08-20 17:15:00'::timestamp 
			AS appointment_recorddate
	UNION ALL	
	SELECT 'Hospital District 2', '+380 310 396 2031', 'pediatrics', '+46 966 292 5642', '2023-09-12 12:15:00', '2023-09-10 14:26:00'
	UNION ALL
	SELECT 'Hospital District 15', '+380 310 396 2045', 'urology', '+86 277 632 5713', '2023-08-28 21:30:00', '2023-09-01 20:32:00'
	UNION ALL
	SELECT 'Hospital District 15', '+380 310 396 3728', 'radiology', '+93 637 292 5631', '2023-08-12 16:40:00', '2023-08-09 12:32:00'
	UNION ALL
	SELECT 'Hospital District 7', '+380 310 396 3823', 'genetics', '+93 637 292 5631', '2023-09-20 13:50:00', '2023-09-18 16:52:00'
	UNION ALL
	SELECT 'Hospital District 4', '+380 310 396 3823', 'genetics', '+28 966 378 5633', '2023-10-10 14:00:00', '2023-10-08 17:52:00'
	) AS new_app
INNER JOIN hospital_data.hospital h
ON new_app.app_hospital_name = h.hospital_name
INNER JOIN hospital_data.doctor d
ON new_app.app_doctor_phone = d.doctor_phone 
INNER JOIN hospital_data.service s
ON new_app.app_service_name = s.service_name
INNER JOIN hospital_data.patient p
ON new_app.app_patient_phone = p.patient_phone
RETURNING *;

INSERT INTO hospital_data.treatment (treatment_appointment_appointmentid, treatment_notes, treatment_recorddate)
SELECT a.appointment_appointmentid, new_treat.treatment_notes, new_treat.treatment_recorddate
FROM (SELECT '2023-08-21 14:13:00'::timestamp AS treat_app_start, 'control in 2 week!' AS treatment_notes, '2023-08-21 15:13:00'::timestamp AS treatment_recorddate
	UNION ALL
	SELECT '2023-09-12 12:15:00', 'no control', '2023-09-12 13:15:00'
	UNION ALL
	SELECT '2023-09-20 13:50:00', 'control in 1 week!', '2023-09-20 14:50:00'
	UNION ALL
	SELECT '2023-10-10 14:00:00', 'control in 1 month!', '2023-10-10 14:30:00'
	UNION ALL
	SELECT '2023-08-12 16:40:00', 'no control', '2023-08-12 17:40:00'
	UNION ALL
	SELECT '2023-08-28 21:30:00', 'control in 1 year!', '2023-08-28 22:00:00') AS new_treat
INNER JOIN hospital_data.appointment a
ON new_treat.treat_app_start = a.appointment_start 
RETURNING *;

INSERT INTO hospital_data.treatmedi (treatmedi_treatment_treatmentid, treatmedi_medicine_medicineid, treatmedi_quantity, 
			treatmedi_dosagedesc, treatmedi_recorddate)
SELECT t.treatment_treatmentid, m.medicine_medicineid, new_tm.treatmedi_quantity, new_tm.treatmedi_dosagedesc,
			new_tm.treatmedi_recorddate
FROM (SELECT '2023-08-21 15:13:00'::timestamp AS tm_treat_recorddate, 'pravastatin' AS tm_medicine_name, 2 AS treatmedi_quantity,
	'2 per day' AS treatmedi_dosagedesc, '2023-08-21 15:33:00'::timestamp AS treatmedi_recorddate
	UNION ALL
	SELECT '2023-09-12 13:15:00', 'Moisture Renew', 3, '1 per week', '2023-09-12 13:45:00'
	UNION ALL
	SELECT '2023-09-20 14:50:00', 'Aspirin', 1, '3 per day', '2023-09-20 15:20:00'
	UNION ALL
	SELECT '2023-10-10 14:30:00', 'RISPERIDONE', 2, '1 per week', '2023-10-10 14:50:00'
	UNION ALL
	SELECT '2023-08-12 17:40:00', 'Heparin', 1, '2 per day', '2023-08-12 17:50:00'
	UNION ALL
	SELECT '2023-08-28 22:00:00', 'Desmopressin', 4, '2 per day', '2023-08-28 22:50:00') AS new_tm
INNER JOIN hospital_data.treatment t
ON new_tm.tm_treat_recorddate = t.treatment_recorddate 
INNER JOIN hospital_data.medicine m
ON new_tm.tm_medicine_name = m.medicine_name 
RETURNING *;
	

-- Find doctors who have had a workload of fewer than 5 patients per month over the last two months.

-- with join:
SELECT d.doctor_fullname, count(a.appointment_appointmentid) AS workload
FROM hospital_data.doctor d 
INNER JOIN hospital_data.appointment a 
ON d.doctor_doctorid = a.appointment_doctor_doctorid 
WHERE a.appointment_start BETWEEN '2023-09-01 00:00:00' AND '2023-10-31 23:59:59'
GROUP BY d.doctor_fullname
HAVING count(a.appointment_appointmentid) < 5;

-- or using join and subquery together:

SELECT doctor_fullname, workload 
FROM (SELECT d.doctor_fullname,
			count(a.appointment_appointmentid) AS workload
			FROM hospital_data.doctor d 
			INNER JOIN hospital_data.appointment a 
			ON d.doctor_doctorid = a.appointment_doctor_doctorid
			WHERE a.appointment_start BETWEEN '2023-09-01 00:00:00' AND '2023-10-31 23:59:59'
			GROUP BY d.doctor_fullname) AS count_work
			WHERE workload < 5;
