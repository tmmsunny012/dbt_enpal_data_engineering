WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'deal_changes') }}
)

SELECT
    deal_id,
    change_time AS changed_at,
    changed_field_key,
    new_value,

    -- Extract month for reporting
    DATE_TRUNC('month', change_time) AS change_month

FROM source