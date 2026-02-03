/*
    Intermediate model: One row per deal with creation metadata.

    Source: stg_deal_changes where changed_field_key = 'add_time'
    Note: Deduplicated by taking earliest creation time per deal.
*/

WITH deal_creation AS (
    SELECT
        deal_id,
        MIN(changed_at) AS created_at,
        MIN(change_month) AS created_month
    FROM {{ ref('stg_deal_changes') }}
    WHERE changed_field_key = 'add_time'
    GROUP BY deal_id
)

SELECT
    deal_id,
    created_at,
    created_month

FROM deal_creation
