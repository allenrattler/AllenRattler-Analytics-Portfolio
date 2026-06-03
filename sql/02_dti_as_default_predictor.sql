-- ============================================================
-- FILE:    02_dti_as_default_predictor.sql
-- PROJECT: Finance Credit Risk Analysis
-- AUTHOR:  Allen Rattler
-- GITHUB:  AllenRattler-Analytics-Portfolio
-- BRANCH:  Finance-Credit-Risk-Analysis
--
-- BUSINESS QUESTION (Q2):
--   Does a borrower's debt-to-income ratio meaningfully
--   separate defaulters from non-defaulters — and does
--   this pattern hold consistently across loan purposes?
--
-- RATIONALE:
--   DTI measures how much of a borrower's gross monthly
--   income is already committed to debt payments. A high DTI
--   means less financial cushion when unexpected expenses hit.
--   Lenders use DTI as a primary underwriting guardrail, but
--   its predictive power varies by loan purpose — a borrower
--   consolidating debt at high DTI may be more intentional
--   about repayment than one taking a vacation loan.
--
-- SQL TECHNIQUES:
--   CASE banding — Groups DTI into four labeled bands
--   (Low/Moderate/High/Very High) matching standard lending
--   underwriting thresholds. More readable and business-friendly
--   than raw numeric ranges in a dashboard filter.
--
--   AVG() OVER (PARTITION BY loan_purpose) — Calculates the
--   average DTI for each loan purpose independently, enabling
--   within-purpose comparison rather than a global average
--   that would obscure purpose-level differences.
--
-- KEY FINDINGS:
--   - Educational loans at Very High DTI (>50%): 57.14%
--     default rate — highest in the portfolio
--   - Debt consolidation defies expectations: High DTI band
--     (18.87%) defaults LESS than Low DTI (26.09%) —
--     intentionality of repayment matters as much as capacity
--   - purpose_avg_dti is uniform across all purposes (~25%),
--     meaning risk differences come from what borrowers do
--     with the money, not how much debt they carry
-- ============================================================


-- ── CTE 1: Filter to valid DTI and status records ─────────────
-- Exclude DTI values flagged as impossible (> 100%)
-- and standardize loan_status to a binary outcome.

WITH valid_dti AS (
    SELECT
        loan_id,
        loan_purpose,
        loan_grade,
        dti_clean                               AS dti,
        loan_status,
        charged_off_amount,
        loan_amount_clean                       AS loan_amount,
        CASE
            WHEN loan_status IN ('Charged Off','Default')
            THEN 1 ELSE 0
        END                                     AS is_default
    FROM loans_clean
    WHERE dti_flag          = 'OK'
      AND loan_amount_flag  = 'OK'
      AND date_sequence_flag = 'OK'
),


-- ── CTE 2: Assign DTI bands ───────────────────────────────────
-- Standard lending thresholds:
--   < 20%   = Low        (comfortably within guidelines)
--   20-35%  = Moderate   (acceptable, standard approval range)
--   36-50%  = High       (elevated — scrutiny required)
--   > 50%   = Very High  (exceeds most lender cutoffs)
--
-- AVG() OVER (PARTITION BY loan_purpose) computes the average
-- DTI for each purpose across all loans in that purpose,
-- regardless of the current row's DTI band.

dti_banded AS (
    SELECT
        loan_id,
        loan_purpose,
        loan_grade,
        dti,
        is_default,
        charged_off_amount,
        loan_amount,
        CASE
            WHEN dti < 20              THEN '1 - Low (<20%)'
            WHEN dti BETWEEN 20 AND 35 THEN '2 - Moderate (20-35%)'
            WHEN dti BETWEEN 36 AND 50 THEN '3 - High (36-50%)'
            ELSE                            '4 - Very High (>50%)'
        END                           AS dti_band,
        AVG(dti) OVER (
            PARTITION BY loan_purpose
        )                             AS avg_dti_for_purpose
    FROM valid_dti
),


-- ── CTE 3: Aggregate by purpose and DTI band ──────────────────
-- Summarize default counts, rates, and charge-off amounts
-- within each loan_purpose + dti_band combination.

purpose_dti_summary AS (
    SELECT
        loan_purpose,
        dti_band,
        ROUND(AVG(avg_dti_for_purpose), 2)      AS purpose_avg_dti,
        COUNT(*)                                 AS total_loans,
        SUM(is_default)                          AS total_defaults,
        ROUND(
            SUM(is_default)::NUMERIC
            / NULLIF(COUNT(*), 0) * 100, 2
        )                                        AS default_rate_pct,
        ROUND(AVG(dti), 2)                       AS avg_dti_in_band,
        ROUND(
            SUM(charged_off_amount)
            / NULLIF(SUM(loan_amount), 0) * 100, 2
        )                                        AS pct_loan_value_charged_off
    FROM dti_banded
    GROUP BY loan_purpose, dti_band
)


-- ── Final Output ──────────────────────────────────────────────
-- Order by loan purpose then DTI band so each purpose block
-- reads Low → Very High, showing the default rate gradient.

SELECT
    loan_purpose,
    dti_band,
    purpose_avg_dti,
    total_loans,
    total_defaults,
    default_rate_pct,
    avg_dti_in_band,
    pct_loan_value_charged_off
FROM purpose_dti_summary
WHERE total_loans >= 5
ORDER BY loan_purpose, dti_band;
