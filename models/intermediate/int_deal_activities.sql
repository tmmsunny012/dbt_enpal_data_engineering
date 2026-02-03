/*
    Intermediate model: Completed sales activities per deal.

    Purpose:
    - Tracks completion of key sales activities (calls/meetings)
    - Maps activity types to funnel sub-steps 2.1 and 3.1
    - Filters to only completed activities

    Grain: One row per completed sales activity (meeting or sc_2)

    Business Context:
    - 'meeting' = Sales Call 1 → Funnel step 2.1 (between Qualified Lead and Needs Assessment)
    - 'sc_2' = Sales Call 2 → Funnel step 3.1 (between Needs Assessment and Proposal)
    - These sub-steps track important sales touchpoints not captured by stage transitions
    - Activities are marked as completed when sales rep marks them done in Pipedrive
*/

WITH completed_activities AS (
    SELECT
        a.deal_id,
        a.activity_type_code,
        a.due_at,  -- Timestamp when activity was completed

        -- Format month for reporting (YYYY-MM)
        TO_CHAR(DATE_TRUNC('month', a.due_at), 'YYYY-MM') AS activity_month,

        -- Enrich with human-readable activity type name
        at.activity_type_name

    FROM {{ ref('stg_activities') }} a
    LEFT JOIN {{ ref('stg_activity_types') }} at
        ON a.activity_type_code = at.activity_type_code

    -- Filter to completed activities only
    WHERE a.is_completed = 'true'
)

SELECT
    -- Foreign key
    deal_id,

    -- Activity identifiers
    activity_type_code,  -- Code (meeting, sc_2)
    activity_type_name,  -- Human-readable name

    -- Activity timestamp
    due_at AS completed_at,  -- When activity was completed
    activity_month,  -- Month for reporting (YYYY-MM)

    -- Map to funnel sub-step name for reporting
    -- This makes it easier to union with stage-based funnel metrics
    CASE activity_type_code
        WHEN 'meeting' THEN 'Sales Call 1'  -- Funnel step 2.1
        WHEN 'sc_2' THEN 'Sales Call 2'      -- Funnel step 3.1
        ELSE 'Other'  -- Filtered out below, but included for safety
    END AS funnel_activity_name

FROM completed_activities

-- Only include activities that map to funnel sub-steps
WHERE activity_type_code IN ('meeting', 'sc_2')
