-- ============================================================
-- FILE:    05_risk_adjusted_return.sql
-- PROJECT: Finance Credit Risk Analysis
-- AUTHOR:  Allen Rattler
-- GITHUB:  AllenRattler-Analytics-Portfolio
-- BRANCH:  Finance-Credit-Risk-Analysis
--
-- BUSINESS QUESTION (Q5):
--   Are high-grade loans generating sufficient interest revenue
--   relative to their default losses — or are certain loan
--   grades quietly delivering a negative net yield?
--
-- RATIONALE:
--   A loan grade exists to price risk. Grade A loans carry
--   low interest rates because they are expected to default
--   rarely. Grade G loans carry high rates to compensate for
--   frequent defaults. But if Grade G defaults are so frequent
--   that interest collected never covers losses, the high rate
--   is an illusion of profitability. Net yield reveals the
--   truth — and in this portfolio, the truth is uncomfortable.
--
-- SQL TECHNIQUES:
--   4-CTE pipeline — Each CTE builds on the last with a clear
--   separation of concerns, making complex analytical logic
--   readable and maintainable:
--     CTE 1 (valid_loans):       Filter and qualify records
--     CTE 2 (grade_financials):  Aggregate revenue and loss
--     CTE 3 (net_yield_calc):    Compute the net yield metric
--     Final SELECT:              Apply composite risk scoring
--
--   Net yield formula:
--     (interest_collected - charged_off) / total_funded
--   A positive value = profitable grade.
--   A negative value = losses exceeded interest income.
--
--   Composite risk score:
--     (default_rate_pct * 0.6) + (GREATEST(0, -net_yield) * 0.4)
--   Default rate weighted 60% as primary driver.
--   GREATEST(0, ...) prevents negative yield from reducing
--   the risk score — a money-losing grade should be penalized,
--   not rewarded.
--
--   CASE-based risk tier label — Converts the composite score
--   into an executive-readable label (Low/Moderate/High/Critical)
--   for Power BI KPI card display.
--
-- KEY FINDINGS:
--   - Grade A: net_yield_pct = -0.81% — the ONLY underwater grade.
--     Interest collected ($1.71M) < charged off ($1.81M).
--     The "safest" grade is quietly losing money.
--   - Grade G: net_yield_pct = +33.97% — most profitable grade.
--     High rates (33.92% avg) more than offset losses.
--   - Grade F: highest composite_risk_score (15.31) —
--     combines high default rate with only moderate yield.
--   - All 7 grades land in "High Risk" tier (scores 12–16),
--     indicating uniformly elevated portfolio-wide risk.
--   - Grade label and actual profitability are not the same thing.
-- ============================================================


-- ── CTE 1: Filter to complete, valid loan records ─────────────

WITH valid_loans AS (
    SELECT
        loan_id,
        loan_grade,
        loan_amount_clean                       AS loan_amount,
        interest_rate_clean                     AS interest_rate,
        loan_term_months,
        loan_status,
        total_payment,
        principal_received,
        interest_received,
        charged_off_amount,
        CASE
            WHEN loan_status IN ('Charged Off','Default')
            THEN 1 ELSE 0
        END                                     AS is_default
    FROM loans_clean
    WHERE loan_amount_flag    = 'OK'
      AND interest_rate_flag  = 'OK'
      AND grade_mismatch_flag = 'OK'
      AND date_sequence_flag  = 'OK'
),


-- ── CTE 2: Aggregate financial performance by loan grade ──────
-- Compute total funded, collected, charged off, and default
-- counts at the grade level.
-- avg_interest_rate confirms whether rate pricing aligns with
-- the default risk we observe in the portfolio.

grade_financials AS (
    SELECT
        loan_grade,
        COUNT(*)                                    AS total_loans,
        SUM(is_default)                             AS total_defaults,
        ROUND(AVG(interest_rate), 2)                AS avg_interest_rate,
        ROUND(SUM(loan_amount), 2)                  AS total_funded,
        ROUND(SUM(interest_received), 2)            AS total_interest_collected,
        ROUND(SUM(principal_received), 2)           AS total_principal_collected,
        ROUND(SUM(charged_off_amount), 2)           AS total_charged_off,
        ROUND(SUM(total_payment), 2)                AS total_payments_received
    FROM valid_loans
    GROUP BY loan_grade
),


-- ── CTE 3: Calculate net yield per grade ──────────────────────
-- Net yield = (interest_collected - charged_off) / total_funded
--
-- Answers: for every dollar lent, how many cents did we retain
-- after absorbing losses?
-- Positive = profitable grade.
-- Negative = losses exceeded all interest income.
--
-- default_rate_pct calculated here for use in the composite
-- risk score in the final SELECT.

net_yield_calc AS (
    SELECT
        loan_grade,
        total_loans,
        total_defaults,
        avg_interest_rate,
        total_funded,
        total_interest_collected,
        total_charged_off,
        total_payments_received,
        ROUND(
            total_defaults::NUMERIC
            / NULLIF(total_loans, 0) * 100, 2
        )                                           AS default_rate_pct,
        ROUND(
            (total_interest_collected - total_charged_off)
            / NULLIF(total_funded, 0) * 100, 2
        )                                           AS net_yield_pct
    FROM grade_financials
)


-- ── Final Output: Composite risk score and tier label ─────────
-- Composite risk score formula:
--   (default_rate_pct * 0.6) + (GREATEST(0, -net_yield_pct) * 0.4)
--
-- Weighting rationale:
--   60% default rate — primary driver; a frequently-defaulting
--   grade is fundamentally broken regardless of yield.
--   40% net yield penalty — captures grades where the math
--   doesn't work even after accounting for interest income.
--
-- GREATEST(0, ...) is critical: prevents a negative yield from
-- SUBTRACTING from the risk score. A money-losing grade must
-- increase risk score, not reduce it.

SELECT
    loan_grade,
    total_loans,
    total_defaults,
    default_rate_pct,
    avg_interest_rate,
    total_funded,
    total_interest_collected,
    total_charged_off,
    net_yield_pct,
    ROUND(
        (default_rate_pct * 0.6)
        + (GREATEST(0, -net_yield_pct) * 0.4), 2
    )                                               AS composite_risk_score,
    CASE
        WHEN (default_rate_pct * 0.6)
           + (GREATEST(0, -net_yield_pct) * 0.4) < 5
        THEN 'Low Risk'
        WHEN (default_rate_pct * 0.6)
           + (GREATEST(0, -net_yield_pct) * 0.4) < 12
        THEN 'Moderate Risk'
        WHEN (default_rate_pct * 0.6)
           + (GREATEST(0, -net_yield_pct) * 0.4) < 20
        THEN 'High Risk'
        ELSE 'Critical Risk'
    END                                             AS risk_tier_label,
    RANK() OVER (
        ORDER BY net_yield_pct DESC
    )                                               AS yield_rank
FROM net_yield_calc
ORDER BY composite_risk_score DESC;
