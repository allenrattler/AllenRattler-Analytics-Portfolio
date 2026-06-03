-- ============================================================
-- FILE:    01_default_rate_by_credit_tier.sql
-- PROJECT: Finance Credit Risk Analysis
-- AUTHOR:  Allen Rattler
-- GITHUB:  AllenRattler-Analytics-Portfolio
-- BRANCH:  Finance-Credit-Risk-Analysis
--
-- BUSINESS QUESTION (Q1):
--   Which credit score tiers and loan grades carry the highest
--   default burden — and how do they rank relative to each other?
--
-- RATIONALE:
--   Credit score is the foundational risk signal in consumer
--   lending. Before any other variable is considered, lenders
--   need to know whether their grade assignments are actually
--   separating risk correctly. If Grade A loans are defaulting
--   at a similar rate to Grade C loans, the grading model is
--   broken.
--
-- SQL TECHNIQUES:
--   NTILE(5) — Divides borrowers into 5 equal credit score
--              quintiles (Q1 = lowest scores, Q5 = highest).
--              More meaningful than fixed bands because it
--              adapts to the actual score distribution in the
--              portfolio rather than arbitrary cutoffs.
--
--   Dual RANK() — Two independent RANK() window functions:
--              one on default_rate_pct, one on total_charged_off.
--              This surfaces the key insight that rate rank and
--              dollar rank tell different stories — a grade can
--              rank highest on rate but low on dollars due to
--              low loan volume (and vice versa).
--
-- KEY FINDINGS:
--   - Grade G (quintile 3): highest default rate at 35.71% (rank 1)
--   - Grade A (quintile 3): 29.75% default rate (rank 3) —
--     unexpected for the "safest" grade; largest dollar exposure
--   - Grade G ranks #1 on rate but #31 on charged-off dollars
--     due to low loan volume (132 loans total)
-- ============================================================


-- ── CTE 1: Filter to analytically valid loans ─────────────────
-- Exclude rows flagged in Power Query for bad credit scores,
-- grade mismatches, or impossible loan amounts.

WITH valid_loans AS (
    SELECT
        loan_id,
        loan_grade,
        loan_subgrade,
        loan_status,
        loan_amount_clean                   AS loan_amount,
        credit_score_clean                  AS credit_score,
        charged_off_amount
    FROM loans_clean
    WHERE credit_score_flag   = 'OK'
      AND grade_mismatch_flag = 'OK'
      AND loan_amount_flag    = 'OK'
),


-- ── CTE 2: Assign credit score quintiles using NTILE ──────────
-- NTILE(5) splits the dataset into 5 equally-sized buckets
-- ordered by credit score ascending.
-- Q1 = bottom 20% of scores (highest risk)
-- Q5 = top 20% of scores (lowest risk)

credit_tiers AS (
    SELECT
        loan_id,
        loan_grade,
        loan_status,
        loan_amount,
        credit_score,
        charged_off_amount,
        NTILE(5) OVER (ORDER BY credit_score ASC) AS credit_quintile
    FROM valid_loans
),


-- ── CTE 3: Aggregate by grade and credit quintile ─────────────
-- Calculate total loans, defaults, default rate, and
-- total charged-off dollar amount per grade per quintile.
-- "Default" includes both Charged Off and Default statuses.

grade_tier_summary AS (
    SELECT
        loan_grade,
        credit_quintile,
        COUNT(*)                                           AS total_loans,
        COUNT(*) FILTER (
            WHERE loan_status IN ('Charged Off', 'Default')
        )                                                  AS total_defaults,
        ROUND(
            COUNT(*) FILTER (
                WHERE loan_status IN ('Charged Off', 'Default')
            )::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2
        )                                                  AS default_rate_pct,
        ROUND(SUM(charged_off_amount), 2)                  AS total_charged_off,
        ROUND(AVG(loan_amount), 2)                         AS avg_loan_amount
    FROM credit_tiers
    GROUP BY loan_grade, credit_quintile
)


-- ── Final Output: Add dual rankings ──────────────────────────
-- RANK() over default_rate_pct surfaces highest-risk
-- grade + quintile combinations at the top.
-- Secondary rank on total_charged_off shows dollar impact
-- independently from rate — these two ranks often diverge.

SELECT
    loan_grade,
    credit_quintile,
    total_loans,
    total_defaults,
    default_rate_pct,
    total_charged_off,
    avg_loan_amount,
    RANK() OVER (
        ORDER BY default_rate_pct DESC
    )                               AS default_rate_rank,
    RANK() OVER (
        ORDER BY total_charged_off DESC
    )                               AS charged_off_dollar_rank
FROM grade_tier_summary
WHERE total_loans >= 5     -- suppress unstable rates from tiny segments
ORDER BY default_rate_rank, loan_grade, credit_quintile;
