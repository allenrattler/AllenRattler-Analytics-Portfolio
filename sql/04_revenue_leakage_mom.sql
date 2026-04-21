-- =============================================================================
-- PROJECT:  Hospital Claim Denial & Revenue Recovery Analysis
-- FILE:     04_revenue_leakage_mom.sql
-- QUESTION: How much total net revenue has been permanently lost to
--           unrecovered denials each month, and what is the cumulative
--           year-to-date leakage figure?
--
-- WHY IT MATTERS:
--     Denial rates and appeal win rates are operational metrics. CFOs and
--     finance teams think in dollars. This query converts every upstream
--     finding into the language of the income statement — connecting the
--     RCM team's daily work directly to the hospital's financial position.
--     The YTD leakage figure is the number that belongs in a board meeting.
--
-- EXPECTED INSIGHT:
--     Monthly leakage will show a consistent baseline with periodic spikes
--     that correspond to months where denial rates worsened (Q2) or appeal
--     recovery dropped. The 3-month rolling average smooths out one-off
--     anomalies to reveal the true underlying trend.
--
-- BUSINESS IMPACT:
--     Quantifies the total financial cost of the denial problem in a format
--     that drives executive action. A CFO seeing $4M+ in YTD leakage will
--     prioritize RCM investment in a way that a 17% denial rate alone
--     will not.
--
-- SQL TECHNIQUES DEMONSTRATED:
--     - Two-CTE approach joining claims and appeals at the month level
--     - LEFT JOIN on month to preserve months with no recoveries
--     - COALESCE() for safe null handling on recovery amounts
--     - LAG() for month-over-month delta calculation
--     - SUM() OVER with PARTITION BY year for YTD running total
--       (PARTITION BY year resets the accumulator on Jan 1 each year)
--     - AVG() OVER with ROWS BETWEEN for 3-month rolling average
--     - leakage_flag CASE classification for Power BI conditional format
--
-- FILTERS APPLIED:
--     - claim_amount_flag = 'Valid'              clean amounts only
--     - date_sequence_flag != 'Sequence Error'   valid appeal dates only
--     - appeal_outcome = 'Won'                   only count real recoveries
--
-- AUTHOR:   Allen Rattler Analytics Portfolio — Project 2
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CTE 1: monthly_claims
-- Aggregates claims to one row per month.
-- Separates total billed, total denied, and total paid amounts.
-- -----------------------------------------------------------------------------

WITH monthly_claims AS (
    SELECT
        DATE_TRUNC('month', service_date)                     AS claim_month,

        -- Total billed to all payers this month
        SUM(claim_amount)                                     AS total_billed,

        -- Total denied this month (gross — before any recoveries)
        SUM(CASE WHEN LOWER(claim_status) = 'denied'
                 THEN claim_amount ELSE 0 END)                AS total_denied,

        -- Total successfully paid this month
        SUM(CASE WHEN LOWER(claim_status) = 'paid'
                 THEN claim_amount ELSE 0 END)                AS total_collected,

        -- Count of denied claims for volume context
        COUNT(CASE WHEN LOWER(claim_status) = 'denied'
                   THEN 1 END)                                AS denied_claim_count

    FROM claims
    WHERE claim_amount_flag = 'Valid'
    GROUP BY DATE_TRUNC('month', service_date)
),

-- -----------------------------------------------------------------------------
-- CTE 2: monthly_recoveries
-- Aggregates won appeal recoveries to one row per resolution month.
-- Uses resolution_date (when money was actually recovered) rather than
-- appeal_date — this matches how cash flow is reported in accounting.
-- -----------------------------------------------------------------------------

monthly_recoveries AS (
    SELECT
        DATE_TRUNC('month', resolution_date)                  AS recovery_month,
        SUM(COALESCE(recovered_amount, 0))                    AS total_recovered
    FROM appeals
    WHERE appeal_outcome        = 'Won'
      AND date_sequence_flag   != 'Sequence Error'
      AND recovered_amount      IS NOT NULL
    GROUP BY DATE_TRUNC('month', resolution_date)
),

-- -----------------------------------------------------------------------------
-- CTE 3: leakage_base
-- Joins monthly claims to monthly recoveries.
-- LEFT JOIN preserves every claims month even when there were no recoveries
-- that month — critical for an accurate time series with no gaps.
-- Net leakage = what was denied minus what was recovered in that month.
-- -----------------------------------------------------------------------------

leakage_base AS (
    SELECT
        mc.claim_month,
        mc.total_billed,
        mc.total_denied,
        mc.total_collected,
        mc.denied_claim_count,
        COALESCE(mr.total_recovered, 0)                       AS total_recovered,

        -- Net leakage: the dollars permanently lost this month
        -- Denied minus recovered = what the hospital will never see
        mc.total_denied
            - COALESCE(mr.total_recovered, 0)                 AS net_leakage,

        -- Denial rate for this month (for context alongside dollar figures)
        ROUND(
            mc.total_denied * 100.0
            / NULLIF(mc.total_billed, 0), 2
        )                                                     AS denial_rate_pct,

        -- Recovery rate for this month
        ROUND(
            COALESCE(mr.total_recovered, 0) * 100.0
            / NULLIF(mc.total_denied, 0), 2
        )                                                     AS recovery_rate_pct

    FROM monthly_claims mc
    LEFT JOIN monthly_recoveries mr
        ON mc.claim_month = mr.recovery_month
),

-- -----------------------------------------------------------------------------
-- CTE 4: with_running_totals
-- Adds all window function calculations on top of the monthly summary.
-- Separating this into its own CTE keeps the logic readable — each
-- window function is clearly labeled and independently understandable.
-- -----------------------------------------------------------------------------

with_running_totals AS (
    SELECT
        claim_month,
        total_billed,
        total_denied,
        total_collected,
        total_recovered,
        denied_claim_count,
        net_leakage,
        denial_rate_pct,
        recovery_rate_pct,

        -- Month-over-month leakage change
        -- Positive = leakage increased (bad), Negative = leakage decreased (good)
        net_leakage - LAG(net_leakage) OVER (
            ORDER BY claim_month
        )                                                     AS leakage_mom_change,

        -- YTD cumulative leakage
        -- PARTITION BY year resets the running total on January 1 each year
        -- Without this partition the total would compound across years
        -- producing a meaningless ever-growing number
        SUM(net_leakage) OVER (
            PARTITION BY DATE_TRUNC('year', claim_month)
            ORDER BY claim_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                     AS ytd_leakage,

        -- 3-month rolling average leakage
        -- Smooths out one-off spikes caused by timing anomalies
        -- (e.g. a batch of appeals all resolving in the same month)
        -- When the monthly figure crosses above this line, leakage is
        -- accelerating. When it drops below, the trend is improving.
        ROUND(AVG(net_leakage) OVER (
            ORDER BY claim_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2)                                                 AS rolling_3m_avg_leakage

    FROM leakage_base
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT
-- leakage_flag classifies each month for Power BI conditional formatting.
-- The $50,000 threshold represents a meaningful operational swing —
-- adjust this value based on the hospital's actual revenue scale.
-- -----------------------------------------------------------------------------

SELECT
    claim_month,
    total_billed,
    total_denied,
    total_collected,
    total_recovered,
    denied_claim_count,
    net_leakage,
    leakage_mom_change,
    ytd_leakage,
    rolling_3m_avg_leakage,
    denial_rate_pct,
    recovery_rate_pct,

    -- Monthly classification — drives conditional formatting in Power BI
    CASE
        WHEN leakage_mom_change >  50000 THEN 'Spike — investigate'
        WHEN leakage_mom_change < -50000 THEN 'Improvement — note driver'
        WHEN leakage_mom_change IS NULL  THEN 'First Month'
        ELSE 'Within normal range'
    END                                                       AS leakage_flag

FROM with_running_totals
ORDER BY claim_month;
