/*
    Reporting model: Monthly sales funnel metrics.

    Tracks deal counts through each funnel step by month.

    Funnel Steps:
    - Step 1: Lead Generation
    - Step 2: Qualified Lead
    - Step 2.1: Sales Call 1
    - Step 3: Needs Assessment
    - Step 3.1: Sales Call 2
    - Step 4: Proposal/Quote Preparation
    - Step 5: Negotiation
    - Step 6: Closing
    - Step 7: Implementation/Onboarding
    - Step 8: Follow-up/Customer Success
    - Step 9: Renewal/Expansion
*/

-- Stage-based funnel steps (1-9)
WITH stage_funnel AS (
    SELECT
        transition_month AS month,
        stage_name AS kpi_name,
        funnel_step,
        COUNT(DISTINCT deal_id) AS deals_count
    FROM {{ ref('int_deal_stage_transitions') }}
    WHERE funnel_step IS NOT NULL
    GROUP BY transition_month, stage_name, funnel_step
),

-- Activity-based funnel steps (2.1 and 3.1)
activity_funnel AS (
    SELECT
        activity_month AS month,
        funnel_activity_name AS kpi_name,
        CASE funnel_activity_name
            WHEN 'Sales Call 1' THEN '2.1'
            WHEN 'Sales Call 2' THEN '3.1'
        END AS funnel_step,
        COUNT(DISTINCT deal_id) AS deals_count
    FROM {{ ref('int_deal_activities') }}
    GROUP BY activity_month, funnel_activity_name
),

-- Combine stage and activity metrics
combined AS (
    SELECT * FROM stage_funnel
    UNION ALL
    SELECT * FROM activity_funnel
)

SELECT
    month,
    kpi_name,
    funnel_step,
    deals_count

FROM combined
ORDER BY month, funnel_step
