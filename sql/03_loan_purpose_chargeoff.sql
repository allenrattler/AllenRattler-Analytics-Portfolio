-- ============================================================
-- FILE:    03_loan_purpose_chargeoff.sql
-- PROJECT: Finance Credit Risk Analysis
-- AUTHOR:  Allen Rattler
-- GITHUB:  AllenRattler-Analytics-Portfolio
-- BRANCH:  Finance-Credit-Risk-Analysis
--
-- BUSINESS QUESTION (Q3):
--   Which loan purposes generate the highest charge-off rates
--   and dollar losses — and how does each purpose rank within
--   the portfolio?
--
-- RATIONALE:
--   Not all loan purposes carry equal risk. A borrower taking
--   a home improvement loan has a tangible asset backing the
--   spend. A borrower taking a vacation loan has nothing.
--   Charge-off rate by purpose reveals which lending categories
--   are quietly draining portfolio value — and whether the
--   interest collected justifies the loss exposure.
--
-- SQL TECHNIQUES:
--   PERCENT_RANK() — Scores each loan purpose on a 0-to-1
--   scale relative to all other purposes on charge-off rate.
--   A score of 1.0 = highest charge-off rate in the portfolio.
--   More granular than RANK() because it shows relative distance
--   between purposes, not just order position.
--
--   CAST(... AS NUMERIC) — Required because PERCENT_RANK()
--   returns double precision in PostgreSQL and ROUND() expects
--   NUMERIC. Same type-handling fix applied in Project 2's
--   05_high_risk_procedure_codes.sql.
--
--   3-CTE rollup — Aggregates at purpose+term level first (CTE 2),
--   then rolls up to purpose-only level (CTE 3) to produce a
--   single charge-off rate per purpose for clean PERCENT_RANK().
--
-- KEY FINDINGS:
--   - Medical: highest charge-off rate at 27.55% (PERCENT_RANK 1.0)
--   - Wedding: highest total charged-off dollars at $855,491
--     despite ranking 2nd on rate — rate vs. dollar divergence
--   - Home improvement: highest avg loss given default ($13,769)
--   - Debt consolidation: 2nd lowest rate (21.59%) — consistent
--     with Q2 finding on intentional repayment behavior
--   - Spread of only ~6 pct points between highest and lowest
--     rates — no clearly "safe" purpose category exists
-- ============================================================


-- ── CTE 1: Filter to complete, valid loan records ─────────────

WITH valid_loans AS (
    SELECT
        loan_id,
        loan_purpose,
        loan_term_months,
        loan_grade,
        loan_amount_clean                       AS loan_amount,
        loan_status,
        total_payment,
        charged_off_amount,
        interest_received,
        CASE
            WHEN loan_status IN ('Charged Off', 'Default')
            THEN 1 ELSE 0
        END                                     AS is_charged_off
    FROM loans_clean
    WHERE loan_amount_flag    = 'OK'
      AND date_sequence_flag  = 'OK'
      AND grade_mismatch_flag = 'OK'
),


-- ── CTE 2: Aggregate by purpose and term ──────────────────────
-- Calculate charge-off metrics at the purpose + term level.
-- avg_loss_given_default only includes loans that charged off,
-- using FILTER to exclude non-defaulted loans from the average.

purpose_summary AS (
    SELECT
        loan_purpose,
        loan_term_months,
        COUNT(*)                                      AS total_loans,
        SUM(is_charged_off)                           AS total_chargeoffs,
        ROUND(
            SUM(is_charged_off)::NUMERIC
            / NULLIF(COUNT(*), 0) * 100, 2
        )                                             AS chargeoff_rate_pct,
        ROUND(SUM(charged_off_amount), 2)             AS total_charged_off_amt,
        ROUND(AVG(loan_amount), 2)                    AS avg_loan_amount,
        ROUND(
            AVG(charged_off_amount)
            FILTER (WHERE is_charged_off = 1), 2
        )                                             AS avg_loss_given_default,
        ROUND(SUM(interest_received), 2)              AS total_interest_collected
    FROM valid_loans
    GROUP BY loan_purpose, loan_term_months
),


-- ── CTE 3: Roll up to purpose level for PERCENT_RANK ──────────
-- PERCENT_RANK requires a single numeric score per entity.
-- Rolling up from purpose+term to purpose-only level produces
-- one charge-off rate per purpose for clean ranking.

purpose_rollup AS (
    SELECT
        loan_purpose,
        SUM(total_loans)                              AS total_loans,
        SUM(total_chargeoffs)                         AS total_chargeoffs,
        ROUND(
            SUM(total_chargeoffs)::NUMERIC
            / NULLIF(SUM(total_loans), 0) * 100, 2
        )                                             AS chargeoff_rate_pct,
        ROUND(SUM(total_charged_off_amt), 2)          AS total_charged_off_amt,
        ROUND(AVG(avg_loss_given_default), 2)         AS avg_loss_given_default,
        ROUND(SUM(total_interest_collected), 2)       AS total_interest_collected
    FROM purpose_summary
    GROUP BY loan_purpose
)


-- ── Final Output: PERCENT_RANK on charge-off rate ─────────────
-- CAST required: PERCENT_RANK() returns double precision in
-- PostgreSQL; ROUND() expects NUMERIC.

SELECT
    loan_purpose,
    total_loans,
    total_chargeoffs,
    chargeoff_rate_pct,
    total_charged_off_amt,
    avg_loss_given_default,
    total_interest_collected,
    ROUND(
        CAST(
            PERCENT_RANK() OVER (
                ORDER BY chargeoff_rate_pct ASC
            ) AS NUMERIC
        ), 4
    )                               AS chargeoff_percent_rank,
    RANK() OVER (
        ORDER BY chargeoff_rate_pct DESC
    )                               AS chargeoff_rank
FROM purpose_rollup
WHERE total_loans >= 5
ORDER BY chargeoff_rank;
