/*
    Intermediate model: Lost deals with loss reasons.

    Tracks when deals are marked as lost and the reason for loss.
*/

WITH lost_deals AS (
    SELECT
        deal_id,
        changed_at AS lost_at,
        change_month AS lost_month,
        CAST(new_value AS INTEGER) AS lost_reason_id
    FROM {{ ref('stg_deal_changes') }}
    WHERE changed_field_key = 'lost_reason'
),

-- Parse lost reason labels from fields JSON
lost_reason_labels AS (
    SELECT
        field_id,
        field_key,
        field_value_options
    FROM {{ ref('stg_fields') }}
    WHERE field_key = 'lost_reason'
),

-- Join to get human-readable loss reasons
with_labels AS (
    SELECT
        ld.deal_id,
        ld.lost_at,
        ld.lost_month,
        ld.lost_reason_id,
        CASE ld.lost_reason_id
            WHEN 1 THEN 'Customer Not Ready'
            WHEN 2 THEN 'Pricing Issues'
            WHEN 3 THEN 'Unreachable Customer'
            WHEN 4 THEN 'Product Mismatch'
            WHEN 5 THEN 'Duplicate Entry'
            ELSE 'Unknown'
        END AS lost_reason_label
    FROM lost_deals ld
)

SELECT
    deal_id,
    lost_at,
    lost_month,
    lost_reason_id,
    lost_reason_label

FROM with_labels
