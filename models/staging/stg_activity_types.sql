WITH source AS (
    SELECT * FROM {{ source('postgres_public', 'activity_types') }}
)

SELECT
    id AS activity_type_id,
    name AS activity_type_name,
    type AS activity_type_code,
    CASE WHEN LOWER(active) = 'yes' THEN TRUE ELSE FALSE END AS is_active

FROM source