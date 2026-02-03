/*
    Intermediate model: Completed sales activities per deal.

    Tracks Sales Call 1 (meeting) and Sales Call 2 (sc_2) completions.
    These map to funnel sub-steps 2.1 and 3.1.
*/

WITH completed_activities AS (
    SELECT
        a.deal_id,
        a.activity_type_code,
        a.due_at,
        TO_CHAR(DATE_TRUNC('month', a.due_at), 'YYYY-MM') AS activity_month,
        at.activity_type_name
    FROM {{ ref('stg_activities') }} a
    LEFT JOIN {{ ref('stg_activity_types') }} at
        ON a.activity_type_code = at.activity_type_code
    WHERE a.is_completed = 'true'
)

SELECT
    deal_id,
    activity_type_code,
    activity_type_name,
    due_at AS completed_at,
    activity_month,

    -- Flag for easier filtering in reporting
    CASE activity_type_code
        WHEN 'meeting' THEN 'Sales Call 1'
        WHEN 'sc_2' THEN 'Sales Call 2'
        ELSE 'Other'
    END AS funnel_activity_name

FROM completed_activities
WHERE activity_type_code IN ('meeting', 'sc_2')
