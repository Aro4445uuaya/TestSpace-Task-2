
-- ============================================================
-- TASK 02: DATA TRANSFORMATION PIPELINE
-- Project: TestSpace
-- Database: testspace_warehouse
-- ============================================================
--
-- OBJECTIVE:
-- Transform raw examination submission data into a clean,
-- structured and analyst-ready final table.
--
-- PIPELINE FLOW:
-- RAW TABLE -> STAGING TABLE -> FINAL TABLE
--
-- ============================================================


-- ============================================================
-- SECTION 1: CREATE STAGING LAYER
-- ============================================================
--
-- Purpose:
-- Create a separate staging table to process raw data.
--
-- Key decisions:
-- 1. mongo_id is the PRIMARY KEY to identify each record.
-- 2. Marks columns use DECIMAL for numeric values.
-- 3. answers column preserves JSON data.
-- 4. Raw table remains unchanged.
--
-- ============================================================

USE testspace_warehouse;

CREATE TABLE IF NOT EXISTS stg_exam_submissions (
    mongo_id VARCHAR(50) PRIMARY KEY,
    workspace_id VARCHAR(50),
    workspace_name VARCHAR(255),
    student_id VARCHAR(100),
    student_name VARCHAR(100),
    dno VARCHAR(50),
    email VARCHAR(255),
    answers JSON,
    score DECIMAL(10,2),
    obtained_marks DECIMAL(10,2),
    total_marks DECIMAL(10,2),
    time_taken VARCHAR(50),
    submitted_at DATETIME
);


-- ============================================================
-- SECTION 2: TRANSFORM RAW DATA INTO STAGING
-- ============================================================
--
-- Purpose:
-- Extract records from the raw table, clean the values,
-- convert data types and remove duplicate records.
--
-- Transformations:
-- TRUNCATE     : Clears previous staging records.
-- TRIM()       : Removes unnecessary spaces.
-- NULLIF()     : Converts empty strings into NULL.
-- CAST()       : Converts marks into DECIMAL values.
-- ROW_NUMBER() : Assigns a sequence number to duplicate groups.
-- rn = 1       : Keeps only the latest record per mongo_id.
--
-- Duplicate selection:
-- Latest submitted_at is preferred.
-- If timestamps match, higher id is preferred.
--
-- ============================================================

USE testspace_warehouse;

-- Clear previous staging data before reloading
TRUNCATE TABLE stg_exam_submissions;


-- Transform raw data and remove duplicates
INSERT INTO stg_exam_submissions (
    mongo_id,
    workspace_id,
    workspace_name,
    student_id,
    student_name,
    dno,
    email,
    answers,
    score,
    obtained_marks,
    total_marks,
    time_taken,
    submitted_at
)
SELECT
    mongo_id,
    NULLIF(TRIM(workspace_id), ''),
    NULLIF(TRIM(workspace_name), ''),
    NULLIF(TRIM(student_id), ''),
    NULLIF(TRIM(student_name), ''),
    NULLIF(TRIM(dno), ''),
    NULLIF(TRIM(email), ''),
    answers,
    CAST(score AS DECIMAL(10,2)),
    CAST(obtained_marks AS DECIMAL(10,2)),
    CAST(total_marks AS DECIMAL(10,2)),
    NULLIF(TRIM(time_taken), ''),
    submitted_at
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY mongo_id
            ORDER BY submitted_at DESC, id DESC
        ) AS rn
    FROM exam_submissions_raw
) AS ranked
WHERE rn = 1;


-- ============================================================
-- SECTION 3: STAGING DATA VALIDATION
-- ============================================================
--
-- Purpose:
-- Verify whether the staging data was loaded correctly.
--
-- Checks:
-- 1. Display all staging records.
-- 2. Count the total staging records.
-- 3. Compare total records with unique mongo_id values.
-- 4. Calculate the number of duplicate records.
--
-- Expected result from our current dataset:
-- Total Records    : 8
-- Unique Records   : 8
-- Duplicate Records: 0
--
-- ============================================================

-- Display staging records
SELECT *
FROM stg_exam_submissions;

-- Count staging records
SELECT COUNT(*) AS staging_count
FROM stg_exam_submissions;

-- Check duplicate records
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT mongo_id) AS unique_records,
    COUNT(*) - COUNT(DISTINCT mongo_id) AS duplicate_records
FROM stg_exam_submissions;


-- ============================================================
-- SECTION 4: CREATE FINAL LAYER
-- ============================================================
--
-- Purpose:
-- Create a separate final table for analysts.
--
-- Key decisions:
-- 1. Keep the final layer separate from staging.
-- 2. Use DECIMAL for marks and percentage.
-- 3. Add a percentage column for performance analysis.
-- 4. Use mongo_id as the PRIMARY KEY.
--
-- ============================================================

USE testspace_warehouse;

CREATE TABLE IF NOT EXISTS fact_exam_submissions (
    mongo_id VARCHAR(50) PRIMARY KEY,
    workspace_id VARCHAR(50),
    workspace_name VARCHAR(255),
    student_id VARCHAR(100),
    student_name VARCHAR(100),
    dno VARCHAR(50),
    email VARCHAR(255),
    score DECIMAL(10,2),
    obtained_marks DECIMAL(10,2),
    total_marks DECIMAL(10,2),
    percentage DECIMAL(5,2),
    time_taken VARCHAR(50),
    submitted_at DATETIME
);


-- ============================================================
-- SECTION 5: LOAD TRANSFORMED DATA INTO FINAL TABLE
-- ============================================================
--
-- Purpose:
-- Transfer clean records from staging into the final table.
--
-- Additional transformation:
-- Calculate student percentage using:
--
-- Percentage = (Obtained Marks / Total Marks) * 100
--
-- CASE:
-- Prevents division by zero when total_marks is zero.
--
-- ON DUPLICATE KEY UPDATE:
-- Updates selected existing values when mongo_id already exists,
-- instead of inserting another record with the same primary key.
--
-- ============================================================

USE testspace_warehouse;

INSERT INTO fact_exam_submissions (
    mongo_id,
    workspace_id,
    workspace_name,
    student_id,
    student_name,
    dno,
    email,
    score,
    obtained_marks,
    total_marks,
    percentage,
    time_taken,
    submitted_at
)
SELECT
    mongo_id,
    workspace_id,
    workspace_name,
    student_id,
    student_name,
    dno,
    email,
    score,
    obtained_marks,
    total_marks,
    CASE
        WHEN total_marks > 0
        THEN ROUND((obtained_marks / total_marks) * 100, 2)
        ELSE NULL
    END,
    time_taken,
    submitted_at
FROM stg_exam_submissions
ON DUPLICATE KEY UPDATE
    score = VALUES(score),
    obtained_marks = VALUES(obtained_marks),
    total_marks = VALUES(total_marks),
    percentage = VALUES(percentage),
    submitted_at = VALUES(submitted_at);


-- ============================================================
-- SECTION 6: FINAL TABLE VALIDATION
-- ============================================================
--
-- Purpose:
-- Verify the final table after data loading.
--
-- Checks:
-- 1. Count the total final records.
-- 2. Display all final records.
-- 3. Verify marks and calculated percentages.
--
-- Expected result from our current dataset:
-- Final Records: 8
--
-- ============================================================

-- Count final records
SELECT COUNT(*) AS final_records
FROM fact_exam_submissions;

-- Display final table records
SELECT *
FROM fact_exam_submissions;

-- Verify marks and calculated percentages
SELECT
    student_name,
    obtained_marks,
    total_marks,
    percentage
FROM fact_exam_submissions;


-- ============================================================
-- TASK 02: COMPLETED
-- ============================================================
--
-- STAGING LAYER          : CREATED
-- TYPE CASTING           : COMPLETED
-- DEDUPLICATION          : COMPLETED
-- FINAL LAYER            : CREATED
-- PERCENTAGE CALCULATION : COMPLETED
-- FINAL VALIDATION       : COMPLETED
--
-- RESULT:
-- A clean, structured and analyst-ready table.
--
-- ============================================================
