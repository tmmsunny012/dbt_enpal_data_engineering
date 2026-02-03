WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'activity') }}
)

SELECT
    activity_id,
    type AS activity_type_code,
    assigned_to_user AS user_id,
    deal_id,
    done AS is_completed,
    due_to AS due_at

FROM source