-- ============================================================
-- FILE:    04_early_delinquency_signal.sql
-- PROJECT: Finance Credit Risk Analysis
-- AUTHOR:  Allen Rattler
-- GITHUB:  AllenRattler-Analytics-Portfolio
-- BRANCH:  Finance-Credit-Risk-Analysis
--
-- BUSINESS QUESTION (Q4):
--   In which payment month do loans first show signs of
--   failure — and does this pattern differ between 36-month
--   and 60-month loan terms?
--
-- RATIONALE:
--   Early delinquency is one of the strongest predictors of
--   eventual charge-off. A loan that misses its 3rd payment
--   is far more likely to charge off than one that first
--   misses at month 18. Identifying the highest-risk months
--   allows a servicer to prioritize outreach and intervention
--   before a late payment becomes a default.
--
-- SQL TECHNIQUES:
--   LAG() OVER (PARTITION BY loan_id ORDER BY payment_month)
--   — Looks back one payment month per loan to compare the
--   current payment status to the previous one. This detects
--   the FIRST missed payment — the moment a loan transitions
--   to MISSED for the first time.
--
--   PARTITION BY loan_term_months — Separates the delinquency
--   timeline by term so 36-month and 60-month loans are compared
--   independently. A month-6 miss is very early in a 60-month
--   loan but mid-journey in a 36-month loan.
--
--   SUM() OVER (PARTITION BY ... ORDER BY ...) — Running total
--   of cumulative missed loans per term, showing how quickly
--   the default pool builds over the life of the portfolio.
--
-- KEY FINDINGS:
--   - 36-month loans: month 6 is the peak first-miss window
--     (10 loans) — optimal intervention point
--   - By month 18 (halfway through 36-month term), 120 loans
--     had first-missed — majority of risk surfaces early
--   - 60-month loans: months 2 and 4 show concentrated early
--     stress despite the longer repayment runway
--
-- KNOWN LIMITATION:
--   pct_that_charged_off = 100% for all rows. This is a
--   synthetic data construction artifact: MISSED status was
--   only assigned to the final payment of loans already
--   labeled Charged Off or Default in the generation script.
--   In production data, this metric would show meaningful
--   variance by payment month and serve as a genuine
--   predictive signal for servicer intervention timing.
-- ============================================================


-- ── CTE 1: Filter payment events to valid records ─────────────
-- Exclude flagged payment dates and negative amounts.
-- Join to loans_clean to bring in loan_term_months and
-- loan_grade for segmentation.

WITH valid_events AS (
    SELECT
        pe.event_id,
        pe.loan_id,
        pe.payment_month,
        pe.payment_date,
        pe.amount_paid,
        pe.payment_status,
        lc.loan_term_months,
        lc.loan_grade,
        lc.loan_status          AS final_loan_status
    FROM payment_events_clean pe
    INNER JOIN loans_clean lc
        ON pe.loan_id = lc.loan_id
    WHERE pe.payment_date_flag  = 'OK'
      AND pe.amount_flag        = 'OK'
      AND lc.date_sequence_flag = 'OK'
),


-- ── CTE 2: Detect first missed payment using LAG() ────────────
-- LAG() retrieves the previous month's payment_status for
-- each loan ordered by payment_month.
-- When current status = MISSED and prior status ≠ MISSED,
-- this marks the first missed payment event.

payment_transitions AS (
    SELECT
        loan_id,
        payment_month,
        payment_status,
        loan_term_months,
        loan_grade,
        final_loan_status,
        LAG(payment_status) OVER (
            PARTITION BY loan_id
            ORDER BY payment_month
        )                           AS prev_payment_status
    FROM valid_events
),


-- ── CTE 3: Isolate first missed payment per loan ──────────────
-- A first miss occurs when:
--   current status = MISSED AND
--   prior status ≠ MISSED (or prior is NULL for month 1)

first_miss AS (
    SELECT
        loan_id,
        payment_month           AS first_miss_month,
        loan_term_months,
        loan_grade,
        final_loan_status
    FROM payment_transitions
    WHERE payment_status = 'MISSED'
      AND (prev_payment_status != 'MISSED'
           OR prev_payment_status IS NULL)
),


-- ── CTE 4: Aggregate by term and first miss month ─────────────
-- Count first misses per payment month, segmented by loan term.
-- pct_that_charged_off shows how dangerous each miss month is —
-- not just how common it is.

delinquency_timeline AS (
    SELECT
        loan_term_months,
        first_miss_month,
        COUNT(*)                    AS loans_first_missed,
        COUNT(*) FILTER (
            WHERE final_loan_status IN ('Charged Off', 'Default')
        )                           AS eventually_charged_off,
        ROUND(
            COUNT(*) FILTER (
                WHERE final_loan_status IN ('Charged Off', 'Default')
            )::NUMERIC
            / NULLIF(COUNT(*), 0) * 100, 2
        )                           AS pct_that_charged_off
    FROM first_miss
    GROUP BY loan_term_months, first_miss_month
)


-- ── Final Output ──────────────────────────────────────────────
-- running_total_missed shows the cumulative first-miss count
-- per term, revealing how quickly the default pool builds.

SELECT
    loan_term_months,
    first_miss_month,
    loans_first_missed,
    eventually_charged_off,
    pct_that_charged_off,
    SUM(loans_first_missed) OVER (
        PARTITION BY loan_term_months
        ORDER BY first_miss_month
    )                           AS running_total_missed
FROM delinquency_timeline
ORDER BY loan_term_months, first_miss_month;
