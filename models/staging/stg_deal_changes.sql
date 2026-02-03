/*
    Staging model: Deal change history from Pipedrive CRM.

    Purpose:
    - Audit trail of all field changes on deals
    - Foundation for tracking deal lifecycle events
    - Renames columns and formats month for reporting

    Grain: One row per deal change event

    Key Fields Tracked:
    - 'add_time': Deal creation timestamp
    - 'stage_id': Stage transitions (funnel progression)
    - 'lost_reason': Why deal was marked as lost

    Business Context:
    - This is an event log - multiple rows per deal
    - Each row represents one field change on one deal
    - Critical for reconstructing deal timeline and funnel metrics
*/

WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'deal_changes') }}
)

SELECT
    -- Foreign key
    deal_id,

    -- Event metadata
    change_time AS changed_at,  -- When the change occurred
    changed_field_key,  -- Which field was changed (add_time, stage_id, lost_reason, etc.)
    new_value,  -- New value after the change (stored as text)

    -- Derived field for monthly reporting (format: YYYY-MM)
    -- Truncates timestamp to month start, then formats as clean string
    TO_CHAR(DATE_TRUNC('month', change_time), 'YYYY-MM') AS change_month

FROM source