CREATE TABLE patients (
    year INT,
    gender TEXT,
    age FLOAT,
    location TEXT,
    race_africanamerican INT,
    race_asian INT,
    race_caucasian INT,
    race_hispanic INT,
    race_other INT,
    hypertension INT,
    heart_disease INT,
    smoking_history TEXT,
    bmi FLOAT,
    hba1c_level FLOAT,
    blood_glucose_level INT,
    diabetes INT,
    clinical_notes TEXT
);

SELECT COUNT(*) FROM patients;
SELECT * FROM patients LIMIT 10;

-- Check for any NULL values in each column
SELECT 
    COUNT(*) FILTER (WHERE year IS NULL) AS year_nulls,
    COUNT(*) FILTER (WHERE gender IS NULL) AS gender_nulls,
    COUNT(*) FILTER (WHERE age IS NULL) AS age_nulls,
    COUNT(*) FILTER (WHERE location IS NULL) AS location_nulls,
    COUNT(*) FILTER (WHERE smoking_history IS NULL) AS smoking_history_nulls,
    COUNT(*) FILTER (WHERE bmi IS NULL) AS bmi_nulls,
    COUNT(*) FILTER (WHERE hba1c_level IS NULL) AS hba1c_nulls,
    COUNT(*) FILTER (WHERE blood_glucose_level IS NULL) AS glucose_nulls,
    COUNT(*) FILTER (WHERE diabetes IS NULL) AS diabetes_nulls,
    COUNT(*) FILTER (WHERE clinical_notes IS NULL) AS notes_nulls
FROM patients;


SELECT MIN(age) AS min_age, MAX(age) AS max_age FROM patients;
SELECT MIN(bmi) AS min_bmi, MAX(bmi) AS max_bmi FROM patients;
SELECT MIN(hba1c_level) AS min_hba1c, MAX(hba1c_level) AS max_hba1c FROM patients;
SELECT MIN(blood_glucose_level) AS min_glucose, MAX(blood_glucose_level) AS max_glucose FROM patients;

SELECT DISTINCT smoking_history FROM patients;
SELECT DISTINCT gender FROM patients;

ALTER TABLE patients
ADD CONSTRAINT chk_age CHECK (age >= 0 AND age <= 120);

ALTER TABLE patients
ADD CONSTRAINT chk_bmi CHECK (bmi >= 10 AND bmi <= 70);

ALTER TABLE patients
ADD CONSTRAINT chk_hba1c CHECK (hba1c_level >= 2 AND hba1c_level <= 15);

ALTER TABLE patients
ADD CONSTRAINT chk_glucose CHECK (blood_glucose_level >= 40 AND blood_glucose_level <= 500);


UPDATE patients
SET smoking_history = CASE
    WHEN smoking_history ILIKE 'no info' THEN 'unknown'
    WHEN smoking_history ILIKE 'not current' THEN 'former'
    ELSE smoking_history
END;

UPDATE patients
SET smoking_history = LOWER(smoking_history);

-- Map inconsistent values
UPDATE patients
SET smoking_history = 'never' WHERE smoking_history IN ('no info', 'not current');

UPDATE patients
SET smoking_history = 'ever' WHERE smoking_history = 'ever';
UPDATE patients
SET smoking_history = 'former' WHERE smoking_history = 'former';
UPDATE patients
SET smoking_history = 'current' WHERE smoking_history = 'current';

DELETE FROM patients
WHERE age < 0 OR age > 120
   OR bmi < 10 OR bmi > 70
   OR hba1c_level < 3 OR hba1c_level > 15
   OR blood_glucose_level < 50 OR blood_glucose_level > 400;

CREATE TABLE race (
    race_id SERIAL PRIMARY KEY,
    race_name VARCHAR(50) UNIQUE
);

INSERT INTO race (race_name)
VALUES ('AfricanAmerican'), ('Asian'), ('Caucasian'), ('Hispanic'), ('Other');

CREATE TABLE demographics (
    patient_id SERIAL PRIMARY KEY,
    year INT CHECK (year > 1900),  -- stores data collection year
    gender VARCHAR(10) CHECK (gender IN ('male','female','other')),
    age NUMERIC CHECK (age > 0),
    location VARCHAR(100),
    race_id INT REFERENCES race(race_id)
);


CREATE TABLE lifestyle (
    lifestyle_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES demographics(patient_id),
    smoking_history VARCHAR(20) CHECK (smoking_history IN ('never','current','former')),
    hypertension INT CHECK (hypertension IN (0,1)),
    heart_disease INT CHECK (heart_disease IN (0,1))
);

CREATE TABLE medical (
    medical_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES demographics(patient_id),
    bmi NUMERIC CHECK (bmi > 0),
    hba1c_level NUMERIC CHECK (hba1c_level > 0),
    blood_glucose_level NUMERIC CHECK (blood_glucose_level > 0),
    diabetes INT CHECK (diabetes IN (0,1)),
    notes TEXT
);

INSERT INTO demographics (patient_id, year, gender, age, location, race_id)
SELECT 
    patient_id,
    year,
    gender,
    age,
    location,
    CASE
        WHEN race_africanamerican = 1 THEN 1
        WHEN race_asian = 1 THEN 2
        WHEN race_caucasian = 1 THEN 3
        WHEN race_hispanic = 1 THEN 4
        WHEN race_other = 1 THEN 5
    END AS race_id
FROM patients;


ALTER TABLE demographics ADD COLUMN year INT;

ALTER TABLE patients
ADD COLUMN patient_id SERIAL PRIMARY KEY;

ALTER TABLE demographics
ADD COLUMN diabetes INT;

UPDATE demographics d
SET diabetes = p.diabetes
FROM patients p
WHERE d.patient_id = p.patient_id;

DROP TABLE IF EXISTS demographics CASCADE;

CREATE TABLE demographics (
    demo_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    gender VARCHAR(20) CHECK (gender IN ('male','female','other')),
    age INT CHECK (age >= 0 AND age <= 120),
    state VARCHAR(50),
    race_id INT REFERENCES race(race_id),
    year INT
);

DROP TABLE IF EXISTS race CASCADE;

CREATE TABLE race (
    race_id SERIAL PRIMARY KEY,
    race_name VARCHAR(50) UNIQUE
);

INSERT INTO race (race_name)
VALUES ('AfricanAmerican'),
       ('Asian'),
       ('Caucasian'),
       ('Hispanic'),
       ('Other')
ON CONFLICT DO NOTHING;

DROP TABLE IF EXISTS demographics CASCADE;

CREATE TABLE demographics (
    demo_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    year INT,
    gender VARCHAR(20) CHECK (gender IN ('male','female','other')),
    age INT CHECK (age >= 0 AND age <= 120),
    location VARCHAR(100),
    race_id INT REFERENCES race(race_id)
);

INSERT INTO demographics (patient_id, year, gender, age, location, race_id)
SELECT
    patient_id,
    year,
    LOWER(gender) AS gender,
    age,
    location,
    CASE
        WHEN race_africanamerican = 1 THEN 1
        WHEN race_asian = 1 THEN 2
        WHEN race_caucasian = 1 THEN 3
        WHEN race_hispanic = 1 THEN 4
        ELSE 5
    END AS race_id
FROM patients;

SELECT d.demo_id, d.patient_id, d.year, d.gender, d.age, d.location, r.race_name
FROM demographics d
JOIN race r ON d.race_id = r.race_id
LIMIT 10;


SELECT column_name
FROM information_schema.columns
WHERE table_name = 'patients';

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

--Gender Distribution
SELECT gender, COUNT(*) AS total_patients
FROM patients
GROUP BY gender;

--Average BMI & HbA1c for diabetics vs non-diabetics
SELECT diabetes,
       ROUND(AVG(bmi)::numeric, 2) AS avg_bmi,
       ROUND(AVG(hba1c_level)::numeric, 2) AS avg_hba1c
FROM patients
GROUP BY diabetes;

--Smoking history vs diabetes prevalence
SELECT smoking_history,
       COUNT(*) AS total_patients,
       ROUND(100.0 * SUM(diabetes)/COUNT(*),2) AS diabetes_percentage
FROM patients
GROUP BY smoking_history;

--Age groups & diabetes correlation
SELECT 
    CASE
        WHEN age < 30 THEN '<30'
        WHEN age BETWEEN 30 AND 45 THEN '30-45'
        WHEN age BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+' 
    END AS age_group,
    COUNT(*) AS total_patients,
    ROUND(100.0 * SUM(diabetes)/COUNT(*),2) AS diabetes_percentage
FROM patients
GROUP BY age_group
ORDER BY age_group;

--Location analysis (states with highest diabetes %)
SELECT location,
       COUNT(*) AS total_patients,
       ROUND(100.0 * SUM(diabetes)/COUNT(*),2) AS diabetes_percentage
FROM patients
GROUP BY location
ORDER BY diabetes_percentage DESC
LIMIT 10;