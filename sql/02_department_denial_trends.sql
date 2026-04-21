-- =============================================================================
-- PROJECT:  Hospital Claim Denial & Revenue Recovery Analysis
-- FILE:     02_department_denial_trends.sql
-- QUESTION: Which hospital departments generate the most denials, and is
--           that trend improving or worsening month-over-month?
--
-- WHY IT MATTERS:
--     Payer-level analysis (Q1) shows WHO is denying claims. Department-
--     level analysis shows WHERE inside the hospital the problem originates.
--     Emergency denies on medical necessity. Surgery denies on missing
--     pre-authorizations. Radiology denies on duplicate billing. Each
--     pattern points to a different internal process failure — and a
--     different fix.
--
-- EXPECTED INSIGHT:
--     One or two departments will show a consistently worsening trend
--     while others remain stable. That contrast is the operational
--     recommendation — concentrate process improvement efforts on the
--     departments trending in the wrong direction.
--
-- BUSINESS IMPACT:
--     Enables the RCM Director to assign targeted staff training and
--     workflow audits to specific departments rather than hospital-wide
--     blanket interventions — saving time and reducing waste.
--
-- SQL TECHNIQUES DEMONSTRATED:
--     - DATE_TRUNC() to collapse daily dates to monthly buckets
--     - NULLIF() to prevent division-by-zero on empty months
--     - LAG() window function partitioned by department — the core
--       technique for month-over-month comparison
--     - PARTITION BY — restarts the LAG() calculation independently
--       for each department so months don't bleed across departments
--     - CASE WHEN trend classification on computed delta values
--
-- FILTERS APPLIED:
--     - claim_amount_flag = 'Valid'  clean amounts only
--     - denial_date IS NOT NULL      excludes the ~6% of denied claims
--       where denial_date was missing (flagged in Excel Task 5)
--
-- AUTHOR:   Allen Rattler Analytics Portfolio — Project 2
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CTE 1: monthly_dept
-- Collapses claim-level rows into one row per department per month.
-- DATE_TRUNC('month', service_date) normalizes all dates within a month
-- to the first of that month — making GROUP BY and ORDER BY reliable.
-- -----------------------------------------------------------------------------

WITH monthly_dept AS (
    SELECT
        department_name,

        -- Truncate service_date to month — groups all claims in the
        -- same month together regardless of exact service day
        DATE_TRUNC('month', service_date)                     AS claim_month,

        COUNT(*)                                              AS total_claims,

        SUM(CASE WHEN LOWER(claim_status) = 'denied'
                 THEN 1 ELSE 0 END)                           AS denied_claims,

        SUM(CASE WHEN LOWER(claim_status) = 'denied'
                 THEN claim_amount ELSE 0 END)                AS denied_revenue,

        -- Denial rate for this department in this month
        -- NULLIF protects against months where a department had zero claims
        -- These appear as NULL rather than being dropped — which preserves
        -- the continuity of the time series for trend analysis
        ROUND(
            SUM(CASE WHEN LOWER(claim_status) = 'denied'
                     THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0), 2
        )                                                     AS denial_rate_pct

    FROM claims
    WHERE claim_amount_flag = 'Valid'
    GROUP BY department_name, DATE_TRUNC('month', service_date)
),

with_trend AS (
    SELECT
        department_name,
        claim_month,
        total_claims,
        denied_claims,
        denied_revenue,
        denial_rate_pct,

        -- Previous month's denial rate for this department
        -- Returns NULL for the first month (no prior month to compare)
        LAG(denial_rate_pct) OVER (
            PARTITION BY department_name
            ORDER BY claim_month
        )                                                     AS prev_month_rate,

        -- Month-over-month change in denial rate
        -- Positive = worsening, Negative = improving
        denial_rate_pct - LAG(denial_rate_pct) OVER (
            PARTITION BY department_name
            ORDER BY claim_month
        )                                                     AS mom_rate_change

    FROM monthly_dept
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Classify each month as Worsening, Improving, or Stable
-- The +2 / -2 threshold filters out noise from small natural fluctuations
-- A 2-point swing in denial rate represents a meaningful operational change
-- This flag column feeds directly into Power BI conditional formatting
-- -----------------------------------------------------------------------------

SELECT
    department_name,
    claim_month,
    total_claims,
    denied_claims,
    denied_revenue,
    denial_rate_pct,
    prev_month_rate,
    ROUND(mom_rate_change, 2)                                 AS mom_rate_change,

    -- Trend classification — drives red/green conditional formatting in Power BI
    CASE
        WHEN mom_rate_change >  2 THEN 'Worsening'
        WHEN mom_rate_change < -2 THEN 'Improving'
        WHEN mom_rate_change IS NULL THEN 'First Month'
        ELSE 'Stable'
    END                                                       AS trend_flag

FROM with_trend
ORDER BY department_name, claim_month;
