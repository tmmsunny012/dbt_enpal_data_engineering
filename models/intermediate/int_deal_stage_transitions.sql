/*
    Intermediate model: Deal stage transitions with stage metadata.

    Tracks when each deal entered each stage of the sales funnel.
*/

WITH stage_changes AS (
    SELECT
        deal_id,
        changed_at AS transitioned_at,
        change_month AS transition_month,
        CAST(new_value AS INTEGER) AS stage_id
    FROM {{ ref('stg_deal_changes') }}
    WHERE changed_field_key = 'stage_id'
),

with_stage_info AS (
    SELECT
        sc.deal_id,
        sc.transitioned_at,
        sc.transition_month,
        sc.stage_id,
        s.stage_name,
        s.funnel_step
    FROM stage_changes sc
    LEFT JOIN {{ ref('stg_stages') }} s
        ON sc.stage_id = s.stage_id
)

SELECT
    deal_id,
    transitioned_at,
    transition_month,
    stage_id,
    stage_name,
    funnel_step

FROM with_stage_info
