/*
    Reporting model: Monthly sales funnel metrics.

    Purpose:
    - Single source of truth for sales funnel KPIs
    - Aggregates deal counts by funnel step and month
    - Combines stage progression, activity completion, and deal loss metrics

    Grain: One row per (month, funnel_step) combination

    Business Context:
    - Used for funnel visualization and conversion rate analysis
    - Tracks 11 total funnel steps (9 stages + 2 activities + Lost)
    - Month format is YYYY-MM for easy time-series analysis
    - Materialized as table for performance (marts layer)

    Funnel Steps (in order):
    - 1: Lead Generation (stage)
    - 2: Qualified Lead (stage)
    - 2.1: Sales Call 1 (activity - first customer touchpoint)
    - 3: Needs Assessment (stage)
    - 3.1: Sales Call 2 (activity - deeper discussion)
    - 4: Proposal/Quote Preparation (stage)
    - 5: Negotiation (stage)
    - 6: Closing (stage)
    - 7: Implementation/Onboarding (stage)
    - 8: Follow-up/Customer Success (stage)
    - 9: Renewal/Expansion (stage)
    - Lost: Deals marked as lost (exit metric)

    Data Sources:
    - int_deal_stage_transitions: Stage-based funnel steps (1-9)
    - int_deal_activities: Activity-based sub-steps (2.1, 3.1)
    - int_deal_losses: Lost deals with categorized reasons
*/

-- Stage-based funnel steps (1-9)
-- Aggregates deal stage transitions by month
WITH stage_funnel AS (
    SELECT
        transition_month AS month,  -- Month when deal entered stage (YYYY-MM)
        stage_name AS kpi_name,  -- Human-readable stage name
        funnel_step,  -- Numeric step (1-9)

        -- Count distinct deals to handle cases where a deal enters same stage multiple times
        COUNT(DISTINCT deal_id) AS deals_count

    FROM {{ ref('int_deal_stage_transitions') }}
    WHERE funnel_step IS NOT NULL  -- Exclude any stages not mapped to funnel
    GROUP BY transition_month, stage_name, funnel_step
),

-- Activity-based funnel steps (2.1 and 3.1)
-- Tracks completion of Sales Call 1 and Sales Call 2
activity_funnel AS (
    SELECT
        activity_month AS month,  -- Month when activity was completed (YYYY-MM)
        funnel_activity_name AS kpi_name,  -- "Sales Call 1" or "Sales Call 2"

        -- Map activity names to funnel sub-step numbers
        CASE funnel_activity_name
            WHEN 'Sales Call 1' THEN '2.1'  -- Between Qualified Lead and Needs Assessment
            WHEN 'Sales Call 2' THEN '3.1'  -- Between Needs Assessment and Proposal
        END AS funnel_step,

        -- Count distinct deals that completed this activity in the month
        COUNT(DISTINCT deal_id) AS deals_count

    FROM {{ ref('int_deal_activities') }}
    GROUP BY activity_month, funnel_activity_name
),

-- Lost deals (exit from funnel)
-- Aggregates deals marked as lost by month
lost_funnel AS (
    SELECT
        lost_month AS month,  -- Month when deal was marked as lost (YYYY-MM)
        'Lost' AS kpi_name,  -- Static label for all lost deals
        'Lost' AS funnel_step,  -- Special funnel step for exits

        -- Count distinct deals marked as lost in the month
        COUNT(DISTINCT deal_id) AS deals_count

    FROM {{ ref('int_deal_losses') }}
    GROUP BY lost_month
),

-- Combine all three funnel metric types
-- UNION ALL preserves all rows (no deduplication needed - different metric types)
combined AS (
    SELECT * FROM stage_funnel
    UNION ALL
    SELECT * FROM activity_funnel
    UNION ALL
    SELECT * FROM lost_funnel
)

SELECT
    month,  -- Time dimension (YYYY-MM format)
    kpi_name,  -- Human-readable metric name
    funnel_step,  -- Step number/identifier (1, 2, 2.1, 3, 3.1, ..., 9, Lost)
    deals_count  -- Number of unique deals at this step in this month

FROM combined

-- Order chronologically and by funnel progression
-- Note: String ordering puts 'Lost' last, which is appropriate
ORDER BY month, funnel_step
