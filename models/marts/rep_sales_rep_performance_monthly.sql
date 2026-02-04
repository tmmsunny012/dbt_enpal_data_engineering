/*
    Reporting model: Monthly sales rep performance metrics.

    Purpose:
    - Tracks sales rep activity and workload by month
    - Demonstrates architecture supports multiple reporting use cases
    - Reuses staging layer assets (stg_users, stg_activities)

    Grain: One row per (month, sales_rep) combination

    Business Context:
    - Shows which reps are most active in completing calls and meetings
    - Enables workload distribution analysis
    - Supports sales team performance management
    - PII-compliant using name_masked from stg_users
*/

SELECT
    TO_CHAR(DATE_TRUNC('month', a.due_at), 'YYYY-MM') AS month,
    u.name_masked AS sales_rep_name,

    -- Activity metrics
    COUNT(DISTINCT a.deal_id) AS deals_worked,
    COUNT(*) AS activities_completed,

    -- Breakdown by activity type
    COUNT(*) FILTER (WHERE a.activity_type_code = 'meeting') AS sales_call_1_completed,
    COUNT(*) FILTER (WHERE a.activity_type_code = 'sc_2') AS sales_call_2_completed,
    COUNT(*) FILTER (WHERE a.activity_type_code IN ('follow_up', 'after_close_call')) AS other_activities

FROM {{ ref('stg_activities') }} a
LEFT JOIN {{ ref('stg_users') }} u
    ON a.user_id = u.user_id
WHERE a.is_completed = 'true'
GROUP BY month, u.name_masked
ORDER BY month, deals_worked DESC
