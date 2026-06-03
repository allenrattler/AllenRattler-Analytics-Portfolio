-- ============================================================
-- FILE:    00_setup.sql
-- PROJECT: Finance Credit Risk Analysis
-- AUTHOR:  Allen Rattler
-- GITHUB:  AllenRattler-Analytics-Portfolio
-- BRANCH:  Finance-Credit-Risk-Analysis
--
-- PURPOSE: Create all tables in the credit_risk database
--          and import cleaned CSV files via pgAdmin Import tool.
--
-- DATABASE: credit_risk
--
-- IMPORT INSTRUCTIONS:
--   Right-click each table in pgAdmin → Import/Export Data
--   → Format: CSV, Header: ON, Delimiter: comma
--   → Select matching file from data/processed/
--
-- TABLE LOAD ORDER (dependency-safe):
--   1. loan_grades_lookup   (35 rows)
--   2. geography_lookup     (50 rows)
--   3. loans_clean          (~3,500 rows)
--   4. payment_events_clean (~23,628 rows)
--
-- NOTE: The COPY command requires superuser privileges and
--   was replaced with pgAdmin Import/Export Data throughout
--   this project — same resolution used in Project 2.
-- ============================================================


-- ── Drop tables if re-running setup ──────────────────────────
DROP TABLE IF EXISTS payment_events_clean;
DROP TABLE IF EXISTS loans_clean;
DROP TABLE IF EXISTS loan_grades_lookup;
DROP TABLE IF EXISTS geography_lookup;


-- ── 1. loan_grades_lookup ─────────────────────────────────────
-- Dimension table: maps loan grade + subgrade to risk tier
-- and base interest rate band.
-- Rows: 35 (7 grades × 5 subgrades)
-- PRIMARY KEY: loan_subgrade (unique — loan_grade has duplicates)
-- NOTE: Power BI relationship uses loan_subgrade, not loan_grade,
--   for this reason. loan_grade appears 5 times per grade letter.

CREATE TABLE loan_grades_lookup (
    loan_grade          VARCHAR(1)    NOT NULL,
    loan_subgrade       VARCHAR(2)    NOT NULL,
    grade_description   VARCHAR(50),
    base_interest_rate  NUMERIC(5,2),
    PRIMARY KEY (loan_subgrade)
);


-- ── 2. geography_lookup ───────────────────────────────────────
-- Dimension table: maps state codes to Census Bureau
-- regions and divisions for geographic aggregation.
-- Rows: 50

CREATE TABLE geography_lookup (
    state_code       CHAR(2)      NOT NULL,
    state_name       VARCHAR(50),
    census_region    VARCHAR(20),
    census_division  VARCHAR(30),
    PRIMARY KEY (state_code)
);


-- ── 3. loans_clean ────────────────────────────────────────────
-- Central fact table: one row per loan application.
-- Rows: ~3,500 after deduplication in Power Query.
-- Flag columns carry all 10 Power Query findings into SQL.
-- Column order matches the Power Query export header exactly
-- to ensure clean pgAdmin import without column mapping errors.

CREATE TABLE loans_clean (
    loan_id                  VARCHAR(10)    PRIMARY KEY,
    loan_grade               VARCHAR(1),
    loan_subgrade            VARCHAR(2),
    grade_mismatch_flag      VARCHAR(15),
    loan_purpose             VARCHAR(50),
    loan_term_months         INTEGER,
    loan_amount              NUMERIC(10,2),
    loan_amount_clean        NUMERIC(10,2),
    loan_amount_flag         VARCHAR(10),
    interest_rate            NUMERIC(5,2),
    interest_rate_clean      NUMERIC(5,2),
    interest_rate_flag       VARCHAR(15),
    installment              NUMERIC(8,2),
    issue_date               DATE,
    first_payment_date       DATE,
    date_sequence_flag       VARCHAR(25),
    loan_status              VARCHAR(30),
    total_payment            NUMERIC(10,2),
    principal_received       NUMERIC(10,2),
    interest_received        NUMERIC(10,2),
    charged_off_amount       NUMERIC(10,2),
    credit_score_clean       INTEGER,
    credit_score_flag        VARCHAR(15),
    credit_score             INTEGER,
    dti                      NUMERIC(6,2),
    dti_clean                NUMERIC(6,2),
    dti_flag                 VARCHAR(20),
    annual_income            NUMERIC(12,2),
    employment_length        VARCHAR(20),
    employment_length_clean  VARCHAR(20),
    home_ownership           VARCHAR(10),
    addr_state               CHAR(2),
    state_name               VARCHAR(50),
    state_flag               VARCHAR(15)
);


-- ── 4. payment_events_clean ───────────────────────────────────
-- Payment history fact table: one row per monthly payment event.
-- Used exclusively in 04_early_delinquency_signal.sql (Q4).
-- Rows: ~23,628 after deduplication in Power Query.

CREATE TABLE payment_events_clean (
    event_id           VARCHAR(10)   PRIMARY KEY,
    loan_id            VARCHAR(10),
    payment_month      INTEGER,
    payment_date       DATE,
    payment_date_flag  VARCHAR(15),
    amount_paid        NUMERIC(8,2),
    amount_flag        VARCHAR(20),
    payment_status     VARCHAR(10)
);


-- ── Validation queries (run after import) ─────────────────────
-- Expected counts:
--   loan_grades_lookup:   35 rows
--   geography_lookup:     50 rows
--   loans_clean:          ~3,500 rows
--   payment_events_clean: ~23,628 rows

SELECT 'loan_grades_lookup'   AS table_name, COUNT(*) AS row_count FROM loan_grades_lookup
UNION ALL
SELECT 'geography_lookup',                   COUNT(*) FROM geography_lookup
UNION ALL
SELECT 'loans_clean',                        COUNT(*) FROM loans_clean
UNION ALL
SELECT 'payment_events_clean',               COUNT(*) FROM payment_events_clean;
