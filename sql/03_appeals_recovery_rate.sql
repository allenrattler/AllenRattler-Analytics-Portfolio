-- =============================================================================
-- PROJECT:  Hospital Claim Denial & Revenue Recovery Analysis
-- FILE:     03_appeals_recovery_rate.sql
-- QUESTION: When a denied claim is appealed, what is the average time to
--           resolution by payer, and what percentage of appealed claims
--           are successfully recovered?
--
-- WHY IT MATTERS:
--     Q1 identifies which payers deny the most. Q3 asks the next logical
--     question: is it worth fighting back? Appeals cost staff time and
--     resources. Knowing which payers have high recovery rates and fast
--     resolution times tells the RCM team where to concentrate appeal
--     effort — and which payers to stop appealing entirely and instead
--     fix the upstream submission process.
--
-- EXPECTED INSIGHT:
--     Some payers deny aggressively on first submission as a cost-reduction
--     tactic, knowing many hospitals won't appeal. Those payers will show
--     high denial rates (Q1) but also high appeal win rates (Q3) — meaning
--     the denial was never justified and the appeal almost always succeeds.
--     That pattern is a direct negotiating point in payer contract talks.
--
-- BUSINESS IMPACT:
--     Enables the RCM team to build a payer-specific appeals prioritization
--     matrix — spend staff time on high-win-rate payers, redirect effort
--     away from low-win-rate payers toward upstream process fixes.
--
-- SQL TECHNIQUES DEMONSTRATED:
--     - Multi-CTE query (three layered CTEs)
--     - INNER JOIN between appeals and claims for claim-level context
--     - LEFT JOIN to preserve denied claims that were never appealed
--       (critical — INNER JOIN would hide the unappealed revenue)
--     - COALESCE() to treat NULL recovered amounts as zero
--     - NULLIF() for safe division
--     - RANK() window function on recovery rate
--     - unappealed_rate_pct — a derived metric revealing untouched revenue
--
-- FILTERS APPLIED:
--     - claim_amount_flag = 'Valid'       clean dollar amounts only
--     - date_sequence_flag != 'Sequence Error'  excludes impossible dates
--
-- AUTHOR:   Allen Rattler Analytics Portfolio — Project 2
-- =============================================================================


-- -----------------------------------------------------------------------------
-- CTE 1: denial_base
-- Isolates all denied claims with valid amounts.
-- This becomes the left side of the final join — we want EVERY denied
-- claim represented, whether it was appealed or not.
-- -----------------------------------------------------------------------------

WITH denial_base AS (
    SELECT
        claim_id,
        payer_name,
        claim_amount,
        denial_reason,
        denial_date,
        department_name
    FROM claims
    WHERE LOWER(claim_status) = 'denied'
      AND claim_amount_flag   = 'Valid'
),

-- -----------------------------------------------------------------------------
-- CTE 2: appeal_outcomes
-- Joins appeals to denied claims and computes time-based metrics.
-- Only includes appeals with valid date sequences (no impossible dates).
-- -----------------------------------------------------------------------------

appeal_outcomes AS (
    SELECT
        a.claim_id,
        a.payer_name,
        a.appeal_date,
        a.resolution_date,
        a.appeal_outcome,
        a.recovered_amount,

        -- Days from denial to appeal submission
        -- Measures how quickly the RCM team responded to the denial
        (a.appeal_date - d.denial_date)                       AS days_to_appeal,

        -- Days from appeal submission to payer resolution
        -- Long resolution times create cash flow problems even when won
        (a.resolution_date - a.appeal_date)                   AS days_to_resolution

    FROM appeals a
    INNER JOIN denial_base d
        ON a.claim_id = d.claim_id

    -- Exclude appeals with date sequence errors flagged in Excel Task 8
    -- These records have impossible chronology and would corrupt time metrics
    WHERE a.date_sequence_flag != 'Sequence Error'
      AND a.appeal_outcome      != 'Pending'
),

-- -----------------------------------------------------------------------------
-- CTE 3: payer_recovery
-- Aggregates appeal outcomes to the payer level.
--
-- CRITICAL DESIGN DECISION — LEFT JOIN vs INNER JOIN:
--     LEFT JOIN preserves ALL denied claims, including those never appealed.
--     An INNER JOIN would silently drop unappealed claims, making recovery
--     rates look artificially high (only measuring claims that were appealed).
--     COALESCE(a.recovered_amount, 0) treats unappealed claims as zero
--     recovery — the honest financial picture.
-- -----------------------------------------------------------------------------

payer_recovery AS (
    SELECT
        d.payer_name,
        COUNT(d.claim_id)                                     AS total_denials,
        COUNT(a.claim_id)                                     AS total_appealed,

        SUM(CASE WHEN a.appeal_outcome = 'Won'
                 THEN 1 ELSE 0 END)                           AS appeals_won,

        SUM(CASE WHEN a.appeal_outcome = 'Lost'
                 THEN 1 ELSE 0 END)                           AS appeals_lost,

        SUM(d.claim_amount)                                   AS total_denied_revenue,

        -- COALESCE ensures unappealed claims count as $0 recovered
        -- rather than being excluded from the sum entirely
        SUM(COALESCE(a.recovered_amount, 0))                  AS total_recovered,

        -- Average calendar days from appeal to resolution
        ROUND(AVG(a.days_to_resolution), 1)                   AS avg_days_to_resolve,

        -- Average days from denial to appeal submission
        ROUND(AVG(a.days_to_appeal), 1)                       AS avg_days_to_appeal,

        -- Win rate: % of appealed claims that were won
        ROUND(
            SUM(CASE WHEN a.appeal_outcome = 'Won'
                     THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(a.claim_id), 0), 2
        )                                                     AS appeal_win_rate_pct,

        -- Net recovery rate: recovered dollars as % of total denied dollars
        -- This is the headline metric for the scatter plot in Power BI
        ROUND(
            SUM(COALESCE(a.recovered_amount, 0)) * 100.0
            / NULLIF(SUM(d.claim_amount), 0), 2
        )                                                     AS net_recovery_rate_pct

    FROM denial_base d
    LEFT JOIN appeal_outcomes a
        ON d.claim_id = a.claim_id
    GROUP BY d.payer_name
)

-- -----------------------------------------------------------------------------
-- FINAL SELECT
-- unappealed_rate_pct is a derived metric not in any source table.
-- It reveals how much denied revenue was never even challenged —
-- often the most surprising finding in the entire project.
-- -----------------------------------------------------------------------------

SELECT
    payer_name,
    total_denials,
    total_appealed,
    appeals_won,
    appeals_lost,
    total_denied_revenue,
    total_recovered,
    avg_days_to_resolve,
    avg_days_to_appeal,
    appeal_win_rate_pct,
    net_recovery_rate_pct,

    -- What % of denied claims were never appealed?
    -- High values here = recoverable revenue being written off without a fight
    ROUND(
        (total_denials - total_appealed) * 100.0
        / NULLIF(total_denials, 0), 2
    )                                                         AS unappealed_rate_pct,

    -- Rank payers by how worthwhile it is to appeal them
    -- Feeds directly into the Power BI scatter plot quadrant analysis
    RANK() OVER (
        ORDER BY net_recovery_rate_pct DESC
    )                                                         AS recovery_rank

FROM payer_recovery
ORDER BY total_denied_revenue DESC;
