/*
    Intermediate model: Deal dimension with creation metadata.

    Purpose:
    - Creates one row per deal with creation timestamp
    - Foundation for deal-level analysis and funnel metrics
    - Handles deduplication of multiple add_time events per deal

    Grain: One row per deal_id

    Deduplication Strategy:
    - Source data contains multiple 'add_time' records per deal
    - Uses MIN() to capture the earliest creation time
    - 1,995 deals had duplicate add_time events (data quality issue)

    Business Context:
    - All deals start here with an 'add_time' event in deal_changes
    - created_month is used for cohort analysis and monthly funnel metrics
    - This is the base dimension for all deal-related reporting
*/

WITH deal_creation AS (
    SELECT
        deal_id,

        -- Take earliest timestamp if multiple add_time events exist
        -- This handles source data quality issue where deals have duplicate creation events
        MIN(changed_at) AS created_at,
        MIN(change_month) AS created_month

    FROM {{ ref('stg_deal_changes') }}
    WHERE changed_field_key = 'add_time'  -- Filter to deal creation events only
    GROUP BY deal_id
)

SELECT
    -- Primary key
    deal_id,

    -- Deal creation metadata
    created_at,  -- Exact timestamp when deal was created
    created_month  -- Month of creation (YYYY-MM format) for reporting

FROM deal_creation
