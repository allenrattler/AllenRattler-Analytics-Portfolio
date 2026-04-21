-- =============================================================================
-- PROJECT:  Hospital Claim Denial & Revenue Recovery Analysis
-- FILE:     00_setup.sql
-- PURPOSE:  Create all tables and import cleaned CSV data from Step 2.
--           Run this script first before any analytical queries.
--
-- TABLES CREATED:
--     1. payers          — Reference table: 8 insurance payer records
--     2. departments     — Reference table: 7 hospital department records
--     3. claims          — Fact table: 5,000 cleaned claim records
--     4. appeals         — Fact table: 562 cleaned appeal records
--
-- USAGE:
--     1. Open pgAdmin or your PostgreSQL client
--     2. Create a new database called healthcare_claims
--     3. Run this script in full
--     4. Verify row counts in the confirmation queries at the bottom
--
-- NOTE:
--     Update the file paths in each COPY command to match the location
--     of your data/processed/ folder on your local machine.
--
-- AUTHOR:   Allen Rattler Analytics Portfolio — Project 2
-- =============================================================================


-- -----------------------------------------------------------------------------
-- STEP 1: Create the database schema
-- -----------------------------------------------------------------------------

-- Drop tables if they already exist (safe re-run)
DROP TABLE IF EXISTS appeals;
DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS payers;


-- -----------------------------------------------------------------------------
-- TABLE 1: payers (reference)
-- Clean lookup table — no nulls, no duplicates
-- -----------------------------------------------------------------------------

CREATE TABLE payers (
    payer_id                VARCHAR(10)   PRIMARY KEY,
    payer_name_clean        VARCHAR(100)  NOT NULL,
    payer_type              VARCHAR(50)   NOT NULL,  -- Commercial, Government, Self-Pay
    avg_reimbursement_rate  NUMERIC(5,2)              -- Average % of billed amount paid
);


-- -----------------------------------------------------------------------------
-- TABLE 2: departments (reference)
-- Clean lookup table — no nulls, no duplicates
-- -----------------------------------------------------------------------------

CREATE TABLE departments (
    department_id    VARCHAR(10)   PRIMARY KEY,
    department_name  VARCHAR(100)  NOT NULL,
    dept_code        VARCHAR(10)   NOT NULL,
    avg_claim_value  NUMERIC(10,2)           -- Average claim value for this department
);


-- -----------------------------------------------------------------------------
-- TABLE 3: claims (fact)
-- 5,000 rows after deduplication in Step 2 Excel cleaning
-- Includes flag columns added during Power Query cleaning
-- -----------------------------------------------------------------------------

CREATE TABLE claims (
    claim_id              VARCHAR(20)   PRIMARY KEY,
    patient_id            VARCHAR(20),
    payer_name            VARCHAR(100),   -- Standardized in Power Query Task 1
    department_name       VARCHAR(100),   -- Standardized in Power Query Task 2
    service_date          DATE,
    submission_date       DATE,
    cpt_code              VARCHAR(20),    -- Trimmed in Power Query Task 6
    icd10_code            VARCHAR(20),    -- Trimmed in Power Query Task 7
    claim_amount          NUMERIC(12,2),  -- NULLs preserved from Task 5
    claim_status          VARCHAR(20),    -- Standardized casing in Task 3
    denial_reason         VARCHAR(200),
    denial_date           DATE,
    claim_amount_flag     VARCHAR(20),    -- 'Valid', 'Missing', 'Negative' — Task 5
    cpt_code_flag         VARCHAR(20),    -- 'Valid', 'Invalid Length', etc — Task 6
    icd10_code_flag       VARCHAR(20)     -- 'Valid', 'Invalid Format', etc — Task 7
);


-- -----------------------------------------------------------------------------
-- TABLE 4: appeals (fact)
-- 562 rows — only denied claims that were appealed
-- Includes flag columns added during Power Query cleaning
-- -----------------------------------------------------------------------------

CREATE TABLE appeals (
    appeal_id             VARCHAR(20)   PRIMARY KEY,
    claim_id              VARCHAR(20)   REFERENCES claims(claim_id),
    payer_name            VARCHAR(100),  -- Standardized in appeals Power Query step
    appeal_date           DATE,
    resolution_date       DATE,          -- NULL for pending appeals
    appeal_outcome        VARCHAR(20),   -- 'Won', 'Lost', 'Pending'
    recovered_amount      NUMERIC(12,2), -- NULL if pending or claim_amount was NULL
    days_to_appeal        INTEGER,       -- Days from denial to appeal submission
    date_sequence_flag    VARCHAR(20),   -- 'Valid', 'Sequence Error', 'Pending' — Task 8
    recovery_amount_flag  VARCHAR(30)    -- 'Won - Valid', 'Won - Unquantifiable', etc
);


-- -----------------------------------------------------------------------------
-- STEP 2: Import clean CSV data
-- Update file paths to match your local data/processed/ folder location
-- -----------------------------------------------------------------------------

-- Import payers reference table
COPY payers (
    payer_id,
    payer_name_clean,
    payer_type,
    avg_reimbursement_rate
)
FROM 'C:\Users\allen\OneDrive\Desktop\Road_to_Data_Analyst\Analytics_Portfolio_Projects\Healthcare_Analysis_Project\Hospital-Claim-Denial-Revenue-Recovery\data\processed\payers_lookup.csv'
DELIMITER ','
CSV HEADER;


-- Import departments reference table
COPY departments (
    department_id,
    department_name,
    dept_code,
    avg_claim_value
)
FROM 'C:\Users\allen\OneDrive\Desktop\Road_to_Data_Analyst\Analytics_Portfolio_Projects\Healthcare_Analysis_Project\Hospital-Claim-Denial-Revenue-Recovery\data\processed\departments_lookup.csv'
DELIMITER ','
CSV HEADER;


-- Import claims fact table
COPY claims (
    claim_id,
    patient_id,
    payer_name,
    department_name,
    service_date,
    submission_date,
    cpt_code,
    icd10_code,
    claim_amount,
    claim_status,
    denial_reason,
    denial_date,
    claim_amount_flag,
    cpt_code_flag,
    icd10_code_flag
)
FROM 'C:\Users\allen\OneDrive\Desktop\Road_to_Data_Analyst\Analytics_Portfolio_Projects\Healthcare_Analysis_Project\Hospital-Claim-Denial-Revenue-Recovery\data\processed\claims_clean.csv'
DELIMITER ','
CSV HEADER
NULL 'null';


-- Import appeals fact table
COPY appeals (
    appeal_id,
    claim_id,
    payer_name,
    appeal_date,
    resolution_date,
    appeal_outcome,
    recovered_amount,
    days_to_appeal,
    date_sequence_flag,
    recovery_amount_flag
)
FROM 'C:\Users\allen\OneDrive\Desktop\Road_to_Data_Analyst\Analytics_Portfolio_Projects\Healthcare_Analysis_Project\Hospital-Claim-Denial-Revenue-Recovery\data\processed\appeals_clean.csv'
DELIMITER ','
CSV HEADER
NULL 'null';


-- -----------------------------------------------------------------------------
-- STEP 3: Confirm row counts after import
-- Expected results:
--     payers      →  8 rows
--     departments →  7 rows
--     claims      →  5,000 rows
--     appeals     →  562 rows
-- -----------------------------------------------------------------------------

SELECT 'payers'      AS table_name, COUNT(*) AS row_count FROM payers
UNION ALL
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'claims'      AS table_name, COUNT(*) AS row_count FROM claims
UNION ALL
SELECT 'appeals'     AS table_name, COUNT(*) AS row_count FROM appeals
ORDER BY table_name;
