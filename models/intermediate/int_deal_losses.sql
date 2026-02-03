/*
    Intermediate model: Lost deals with categorized loss reasons.

    Purpose:
    - Tracks when deals exit the funnel by being marked as lost
    - Categorizes loss reasons for analysis
    - Provides exit metrics complementing stage progression metrics

    Grain: One row per lost deal

    Business Context:
    - 6,000 deals marked as lost (important metric previously missing)
    - Lost deals appear as funnel step "Lost" in final reporting
    - Loss reasons help identify pipeline leakage points:
      * Customer Not Ready: Timing issues
      * Pricing Issues: Price sensitivity or budget constraints
      * Unreachable Customer: Communication breakdown
      * Product Mismatch: Product doesn't fit customer needs
      * Duplicate Entry: Data quality issue in CRM

    Loss Reason Mapping:
    - Hardcoded CASE statement based on Pipedrive field configuration
    - Could alternatively parse from field_value_options JSON (see lost_reason_labels CTE)
    - Hardcoded approach chosen for performance and explicitness
*/

WITH lost_deals AS (
    SELECT
        deal_id,
        changed_at AS lost_at,  -- When deal was marked as lost
        change_month AS lost_month,  -- Month for reporting (YYYY-MM)

        -- Convert text new_value to integer lost_reason_id
        CAST(new_value AS INTEGER) AS lost_reason_id

    FROM {{ ref('stg_deal_changes') }}
    WHERE changed_field_key = 'lost_reason'  -- Filter to loss events only
),

-- This CTE shows how to parse options from the fields table
-- Currently not used, but left as documentation of alternative approach
lost_reason_labels AS (
    SELECT
        field_id,
        field_key,
        field_value_options  -- Contains JSON like [{"id":1,"label":"Customer Not Ready"},...]
    FROM {{ ref('stg_fields') }}
    WHERE field_key = 'lost_reason'
),

-- Map numeric IDs to human-readable labels
with_labels AS (
    SELECT
        ld.deal_id,
        ld.lost_at,
        ld.lost_month,
        ld.lost_reason_id,

        -- Map lost_reason_id to descriptive labels
        -- Hardcoded based on Pipedrive configuration
        CASE ld.lost_reason_id
            WHEN 1 THEN 'Customer Not Ready'
            WHEN 2 THEN 'Pricing Issues'
            WHEN 3 THEN 'Unreachable Customer'
            WHEN 4 THEN 'Product Mismatch'
            WHEN 5 THEN 'Duplicate Entry'
            ELSE 'Unknown'  -- Fallback for unexpected values
        END AS lost_reason_label

    FROM lost_deals ld
)

SELECT
    -- Foreign key
    deal_id,

    -- Loss event metadata
    lost_at,  -- Exact timestamp when deal was marked as lost
    lost_month,  -- Month for reporting (YYYY-MM)

    -- Loss reason classification
    lost_reason_id,  -- Numeric ID (1-5)
    lost_reason_label  -- Human-readable label

FROM with_labels
