/*
    Intermediate model: Deal stage transitions with stage metadata.

    Purpose:
    - Tracks every stage change event for each deal
    - Enriches stage IDs with human-readable names and funnel steps
    - Foundation for funnel metrics (steps 1-9)

    Grain: One row per deal stage transition event

    Business Context:
    - Deals move through stages as they progress through the sales pipeline
    - A deal may move forward, backward, or skip stages
    - Each transition is timestamped, allowing time-in-stage analysis
    - Funnel steps 1-9 come from stage transitions
    - Sub-steps 2.1 and 3.1 come from activities (see int_deal_activities)
*/

WITH stage_changes AS (
    SELECT
        deal_id,
        changed_at AS transitioned_at,  -- When deal entered this stage
        change_month AS transition_month,  -- Month of transition (YYYY-MM)

        -- Convert text new_value to integer stage_id
        CAST(new_value AS INTEGER) AS stage_id

    FROM {{ ref('stg_deal_changes') }}
    WHERE changed_field_key = 'stage_id'  -- Filter to stage change events only
),

-- Join with stage lookup to get human-readable names and funnel step numbers
with_stage_info AS (
    SELECT
        sc.deal_id,
        sc.transitioned_at,
        sc.transition_month,
        sc.stage_id,

        -- Enrichment from stages dimension
        s.stage_name,  -- Human-readable stage name (e.g., "Lead Generation")
        s.funnel_step  -- Funnel step number (1-9)

    FROM stage_changes sc
    LEFT JOIN {{ ref('stg_stages') }} s
        ON sc.stage_id = s.stage_id
)

SELECT
    -- Foreign key
    deal_id,

    -- Event timestamp
    transitioned_at,  -- Exact timestamp of stage transition
    transition_month,  -- Month for reporting (YYYY-MM)

    -- Stage identifiers
    stage_id,  -- Numeric stage ID from Pipedrive
    stage_name,  -- Human-readable stage name
    funnel_step  -- Funnel step number (1-9)

FROM with_stage_info
