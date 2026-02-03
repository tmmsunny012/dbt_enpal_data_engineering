WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'deal_changes') }}
)

SELECT
    deal_id,
    change_time AS changed_at,
    changed_field_key,
    new_value,

    -- Extract month for reporting (formatted as YYYY-MM)
    TO_CHAR(DATE_TRUNC('month', change_time), 'YYYY-MM') AS change_month

FROM source