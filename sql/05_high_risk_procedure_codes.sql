-- =============================================================================
-- PROJECT:  Hospital Claim Denial & Revenue Recovery Analysis
-- FILE:     05_high_risk_procedure_codes.sql
-- QUESTION: Which CPT procedure codes and ICD-10 diagnosis codes have the
--           highest denial probability, and can we flag them as pre-
--           submission risk indicators?
--
-- WHY IT MATTERS:
--     Every other query in this project is retrospective — measuring damage
--     that has already occurred. This query is forward-looking. By scoring
--     every CPT/ICD-10 combination on historical denial probability, the
--     analysis transforms from a reporting tool into an early warning system.
--     Billing staff can intervene BEFORE submission — adding documentation,
--     verifying authorization, or escalating to a physician.
--
-- EXPECTED INSIGHT:
--     A small number of CPT/ICD-10 combinations will account for a
--     disproportionate share of total denied revenue. Flagging those
--     combinations for pre-submission review is the highest-ROI intervention
--     available to the RCM team.
--
-- BUSINESS IMPACT:
--     In a production environment, this risk score table becomes a live
--     lookup that the billing system queries at claim submission time.
--     Even a simple flag that catches 50% of future denials before
--     submission would represent significant recovered revenue annually.
--
-- SQL TECHNIQUES DEMONSTRATED:
--     - Three-layer CTE architecture for complex aggregation
--     - Minimum volume threshold (WHERE total_claims >= 10) to exclude
--       statistically meaningless one-off denials
--     - Composite risk score: weighted blend of two signals
--       (denial rate + breadth of payer denials)
--     - PERCENT_RANK() window function — places each code combination
--       on a 0-100 percentile scale relative to all others
--     - Dual RANK() — risk rank vs revenue impact rank
--     - COUNT(DISTINCT CASE WHEN ...) for conditional distinct counting
--
-- FILTERS APPLIED:
--     - claim_amount_flag = 'Valid'      clean amounts only
--     - cpt_code_flag = 'Valid'          only properly formatted CPT codes
--     - icd10_code_flag = 'Valid'        only properly formatted ICD-10 codes
--     - total_claims >= 10               minimum volume threshold
--
-- AUTHOR:   Allen Rattler Analytics Portfolio — Project 2
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CTE 1: code_level_denials
-- Aggregates claims at the CPT + ICD-10 + payer level.
-- This granularity lets us see whether a code combination is denied
-- by one specific payer (payer policy) or universally (coding problem).
-- -----------------------------------------------------------------------------

WITH code_level_denials AS (
    SELECT
        cpt_code,
        icd10_code,
        payer_name,
        COUNT(*)                                              AS total_claims,

        SUM(CASE WHEN LOWER(claim_status) = 'denied'
                 THEN 1 ELSE 0 END)                           AS denied_claims,

        SUM(claim_amount)                                     AS total_billed,

        SUM(CASE WHEN LOWER(claim_status) = 'denied'
                 THEN claim_amount ELSE 0 END)                AS denied_amount,

        ROUND(
            SUM(CASE WHEN LOWER(claim_status) = 'denied'
                     THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0), 2
        )                                                     AS denial_rate_pct

    FROM claims

    -- Only include rows with valid codes and valid amounts
    -- Invalid codes from Task 6 and 7 are excluded — they can't be
    -- reliably matched to real procedure/diagnosis combinations
    WHERE claim_amount_flag = 'Valid'
      AND cpt_code_flag     = 'Valid'
      AND icd10_code_flag   = 'Valid'

    GROUP BY cpt_code, icd10_code, payer_name
),

-- -----------------------------------------------------------------------------
-- CTE 2: code_summary
-- Rolls up the payer-level data to the CPT + ICD-10 level.
-- Captures both the overall denial rate and the BREADTH of denials
-- across payers — a code denied by every payer is a more serious
-- problem than one denied by a single aggressive insurer.
-- -----------------------------------------------------------------------------

code_summary AS (
    SELECT
        cpt_code,
        icd10_code,
        SUM(total_claims)                                     AS total_claims_all_payers,
        SUM(denied_claims)                                    AS total_denials_all_payers,
        SUM(total_billed)                                     AS total_billed_all_payers,
        SUM(denied_amount)                                    AS total_denied_all_payers,

        -- Overall denial rate across all payers for this code combination
        ROUND(
            SUM(denied_claims) * 100.0
            / NULLIF(SUM(total_claims), 0), 2
        )                                                     AS overall_denial_rate_pct,

        -- How many distinct payers deny this code combination at >20% rate?
        -- Measures breadth: a code denied by 6 payers is riskier than one
        -- denied by 1 payer, even at the same overall rate
        COUNT(DISTINCT CASE WHEN denial_rate_pct > 20
                            THEN payer_name END)              AS high_deny_payer_count,

        COUNT(DISTINCT payer_name)                            AS total_payer_count

    FROM code_level_denials
    GROUP BY cpt_code, icd10_code
),

-- -----------------------------------------------------------------------------
-- CTE 3: with_risk_score
-- Computes the composite risk score and applies the minimum volume filter.
--
-- RISK SCORE LOGIC:
--     risk_score = (denial_rate * 0.7) + (payer_breadth_pct * 0.3)
--
--     70% weight on denial rate — the primary signal
--     30% weight on payer breadth — the secondary signal
--
--     A code denied by 1 payer at 60% and a code denied by all 8 payers
--     at 40% both need attention — but the breadth signal distinguishes
--     them. The weighted blend captures both dimensions in one number.
--
-- MINIMUM VOLUME THRESHOLD:
--     WHERE total_claims >= 10 excludes codes submitted only once or twice.
--     A code submitted once and denied once = 100% denial rate, but this
--     is statistically meaningless. The threshold prevents noise from
--     distorting the risk rankings.
-- -----------------------------------------------------------------------------

with_risk_score AS (
    SELECT
        cpt_code,
        icd10_code,
        total_claims_all_payers,
        total_denials_all_payers,
        total_billed_all_payers,
        total_denied_all_payers,
        overall_denial_rate_pct,
        high_deny_payer_count,
        total_payer_count,

        -- Composite risk score (0-100 scale)
        ROUND(
            (overall_denial_rate_pct * 0.7)
            + (
                high_deny_payer_count * 1.0
                / NULLIF(total_payer_count, 0) * 100 * 0.3
              ), 2
        )                                                     AS risk_score,

        -- Percentile rank within all code combinations
        -- More operationally useful than raw rate alone:
        -- "This code is in the 94th percentile for denial risk"
        -- is more actionable than "This code has a 38% denial rate"
       ROUND(
    CAST(PERCENT_RANK() OVER (
        ORDER BY overall_denial_rate_pct
    ) * 100 AS NUMERIC), 1
)                                                     AS denial_rate_percentile,

        -- Risk tier classification
        CASE
            WHEN overall_denial_rate_pct >= 40 THEN 'Critical'
            WHEN overall_denial_rate_pct >= 25 THEN 'High'
            WHEN overall_denial_rate_pct >= 10 THEN 'Medium'
            ELSE                                    'Low'
        END                                                   AS risk_tier

    FROM code_summary

    -- Minimum volume filter — excludes statistically insignificant codes
    -- Adjust this threshold based on your actual data volume
    WHERE total_claims_all_payers >= 10
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT
-- Dual RANK() recreates the same analytical lens used in Q1:
--   risk_rank          = most likely to be denied (by score)
--   revenue_impact_rank = most costly when denied (by dollars)
-- A Critical-tier code submitted twice a year is lower priority than a
-- High-tier code submitted 500 times. Both rankings together let the
-- billing team prioritize correctly.
-- -----------------------------------------------------------------------------

SELECT
    cpt_code,
    icd10_code,
    total_claims_all_payers,
    total_denials_all_payers,
    total_denied_all_payers,
    overall_denial_rate_pct,
    risk_score,
    denial_rate_percentile,
    risk_tier,
    high_deny_payer_count,
    total_payer_count,

    -- Rank by composite risk score
    RANK() OVER (
        ORDER BY risk_score DESC
    )                                                         AS risk_rank,

    -- Rank by total denied revenue — volume matters alongside probability
    RANK() OVER (
        ORDER BY total_denied_all_payers DESC
    )                                                         AS revenue_impact_rank

FROM with_risk_score
ORDER BY risk_score DESC;
