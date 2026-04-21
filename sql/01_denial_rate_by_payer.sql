-- =============================================================================
-- PROJECT:  Hospital Claim Denial & Revenue Recovery Analysis
-- FILE:     01_denial_rate_by_payer.sql
-- QUESTION: Which insurance payers have the highest claim denial rates,
--           and what is the total dollar value denied per payer?
--
-- WHY IT MATTERS:
--     Not all payers behave equally. Some insurers deny aggressively on
--     first submission knowing many hospitals won't appeal. Identifying
--     which payers are costing the most — by both rate and dollar volume —
--     tells the RCM team where to focus contract negotiations, pre-
--     authorization workflows, and staff training.
--
-- EXPECTED INSIGHT:
--     The payer with the highest denial RATE is not necessarily the payer
--     with the highest denied REVENUE. A payer denying 22% of high-value
--     surgical claims costs more than one denying 30% of low-value
--     outpatient visits. The dual RANK() exposes that distinction.
--
-- BUSINESS IMPACT:
--     Directly informs payer contract renegotiation priorities and
--     pre-authorization policy changes for high-denial payers.
--
-- SQL TECHNIQUES DEMONSTRATED:
--     - CTE (WITH clause) for layered aggregation
--     - Conditional SUM using CASE WHEN for denial counts
--     - NULLIF() to prevent division-by-zero errors
--     - RANK() window function — dual ranking on rate vs. revenue
--     - ROUND() for clean percentage formatting
--
-- FILTERS APPLIED:
--     - claim_amount_flag = 'Valid'  excludes NULL and negative amounts
--       so dollar totals are accurate and meaningful
--
-- AUTHOR:   Allen Rattler Analytics Portfolio — Project 2
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CTE 1: payer_summary
-- Aggregates total claims, denied claims, and denied revenue per payer.
-- Using a CTE here keeps the RANK() logic in the outer query clean and
-- readable — the window function runs on the already-aggregated result
-- rather than on raw row-level data.
-- -----------------------------------------------------------------------------

WITH payer_summary AS (
    SELECT
        payer_name,

        -- Total claims submitted to this payer
        COUNT(*)                                              AS total_claims,

        -- Count of denied claims only
        -- CASE WHEN inside SUM is more readable than a subquery
        -- and avoids a second pass over the data
        SUM(CASE WHEN LOWER(claim_status) = 'denied'
                 THEN 1 ELSE 0 END)                           AS denied_claims,

        -- Total dollar value of all denied claims
        -- claim_amount_flag filter in WHERE ensures no NULLs or negatives
        SUM(CASE WHEN LOWER(claim_status) = 'denied'
                 THEN claim_amount ELSE 0 END)                AS denied_revenue,

        -- Total dollar value of all claims (billed amount)
        SUM(claim_amount)                                     AS total_billed,

        -- Denial rate as a percentage
        -- NULLIF(COUNT(*), 0) prevents division-by-zero if a payer
        -- somehow has zero claims — safe defensive coding practice
        ROUND(
            SUM(CASE WHEN LOWER(claim_status) = 'denied'
                     THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0), 2
        )                                                     AS denial_rate_pct

    FROM claims

    -- Only include rows with valid claim amounts
    -- This ensures dollar totals are not distorted by missing
    -- or negative values that were flagged in Excel cleaning
    WHERE claim_amount_flag = 'Valid'

    GROUP BY payer_name
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT: Add dual RANK() window functions
-- RANK() vs ORDER BY alone: RANK() lets us answer two different questions
-- simultaneously without running two separate queries.
--   denial_rank        = which payer denies most OFTEN (by rate)
--   revenue_impact_rank = which payer costs the most (by dollars)
-- These two rankings frequently differ — that gap is itself an insight.
-- -----------------------------------------------------------------------------

SELECT
    payer_name,
    total_claims,
    denied_claims,
    denied_revenue,
    total_billed,
    denial_rate_pct,

    -- Rank payers by denial rate — highest rate = rank 1
    RANK() OVER (
        ORDER BY denial_rate_pct DESC
    )                                                         AS denial_rank,

    -- Rank payers by total denied revenue — most dollars lost = rank 1
    -- This ranking often differs from denial_rank, revealing payers
    -- that deny less frequently but on much higher-value claims
    RANK() OVER (
        ORDER BY denied_revenue DESC
    )                                                         AS revenue_impact_rank,

    -- What % of total billed revenue was denied for this payer?
    -- Useful for the Power BI KPI card
    ROUND(
        denied_revenue * 100.0
        / NULLIF(total_billed, 0), 2
    )                                                         AS pct_revenue_denied

FROM payer_summary
ORDER BY denied_revenue DESC;
