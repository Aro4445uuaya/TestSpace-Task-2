
# Task 02 – Data Transformation Pipeline

## 1. Project Overview

This project focuses on transforming raw examination submission data into a clean, structured, and analyst-ready dataset using MySQL.

In Task 1, examination submission records were extracted from MongoDB Atlas and loaded into a MySQL raw landing table.

In Task 2, the raw data is processed through separate staging and final layers using data cleaning, type casting, deduplication, and percentage calculation.

## 2. Objective

The main objective is to build a data transformation pipeline that converts raw examination records into a reliable dataset suitable for analytical queries and reporting.

## 3. Technology Stack

- Database: MySQL
- SQL Environment: MySQL Workbench
- Source Database: MongoDB Atlas
- Target Database: MySQL
- Data Transformation: SQL

## 4. Pipeline Architecture

```text
MongoDB Atlas
      |
      v
Task 1 - Python Extract & Load
      |
      v
Raw Layer
exam_submissions_raw
      |
      v
Staging Layer
stg_exam_submissions
      |
      |-- Data Cleaning
      |-- Type Casting
      |-- Deduplication
      |
      v
Final Layer
fact_exam_submissions
      |
      |-- Percentage Calculation
      |-- Final Validation
      |
      v
Analyst-Ready Dataset
```

## 5. Project Structure

```text
task-02-transform/
│
├── task_02_transform.sql
│
└── README.md
```

## 6. Implementation Details

### 6.1 Staging Layer Creation

Created a separate staging table named `stg_exam_submissions`.

Purpose:

- Keep raw and transformed data separate.
- Prepare data for cleaning and transformation.
- Preserve the original raw table.
- Use appropriate data types for numerical fields.

### 6.2 Data Cleaning and Transformation

Transferred records from the raw table into the staging table.

Transformations performed:

| SQL Function | Purpose |
|---|---|
| `TRIM()` | Removes unnecessary spaces |
| `NULLIF()` | Converts empty strings into NULL |
| `CAST()` | Converts marks into DECIMAL values |
| `ROW_NUMBER()` | Identifies duplicate records |

### 6.3 Deduplication

Used the `ROW_NUMBER()` window function to identify duplicate records based on `mongo_id`.

Selection logic:

- Partition records using `mongo_id`.
- Prefer the latest `submitted_at` value.
- If timestamps match, prefer the higher raw table `id`.
- Retain only the record with row number 1.

### 6.4 Staging Validation

Validated the staging table using SQL aggregate queries.

| Metric | Result |
|---|---:|
| Total Records | 8 |
| Unique Records | 8 |
| Duplicate Records | 0 |

### 6.5 Final Layer Creation

Created a separate final table named `fact_exam_submissions`.

The final table contains:

- Student details
- Workspace details
- Examination marks
- Submission time
- Calculated percentage

### 6.6 Percentage Calculation

Calculated student examination percentage using:

```text
Percentage = (Obtained Marks / Total Marks) * 100
```

Used a SQL `CASE` expression to prevent division by zero when total marks are zero.

### 6.7 Final Data Loading

Loaded transformed records from the staging layer into the final table.

Used `ON DUPLICATE KEY UPDATE` to update selected existing values when a record with the same `mongo_id` already exists.

### 6.8 Final Validation

Executed SQL queries to:

- Count final records.
- Display final table records.
- Verify obtained marks.
- Verify total marks.
- Check calculated percentages.

**Final validation result:**

| Metric | Result |
|---|---:|
| Final Records | 8 |
| Staging Records | 8 |
| Duplicate Records in Staging | 0 |

## 7. Key Decisions

1. Separate staging and final tables were created to maintain clear data layers.
2. The original raw table was preserved without modification.
3. DECIMAL data types were used for marks and percentage calculations.
4. `mongo_id` was selected as the unique record identifier.
5. Duplicate records were handled using the `ROW_NUMBER()` window function.
6. Percentage calculation was included to support examination performance analysis.
7. SQL operations were organised into readable sections.

## 8. How to Run

### Prerequisites

- MySQL Server
- MySQL Workbench
- Task 1 raw table populated in the `testspace_warehouse` database.

### Execution Steps

1. Clone or download this repository.
2. Open MySQL Workbench.
3. Connect to your MySQL Server.
4. Select the `testspace_warehouse` database.
5. Verify that the `exam_submissions_raw` table exists and contains source records.
6. Open `task_02_transform.sql`.
7. Execute the SQL sections in their given order.
8. Verify staging and final table results using the validation queries.

**Important:** The staging table is truncated before each reload. The raw table remains untouched. The final table uses an upsert operation for existing `mongo_id` values.

## 9. Output Tables

| Layer | Table Name | Purpose |
|---|---|---|
| Raw | `exam_submissions_raw` | Original extracted records |
| Staging | `stg_exam_submissions` | Cleaned and deduplicated records |
| Final | `fact_exam_submissions` | Analyst-ready examination records |

## 10. Conclusion

Task 2 successfully demonstrates a structured SQL-based data transformation pipeline using separate staging and final layers.

The implementation includes data cleaning, type casting, deduplication, percentage calculation, and validation.

The resulting final table provides a cleaner and more organised dataset for examination performance analysis.

---

**Project:** TestSpace  
**Internship:** Data Engineering – Task 02  
**Task Level:** Level 2 of 4  
**Status:** Implementation and initial validation completed.
