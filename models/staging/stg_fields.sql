WITH source AS (
    SELECT * FROM {{ source('postgres_public', 'fields') }}
)

SELECT
    id AS field_id,
    field_key,
    name AS field_name,
    field_value_options

FROM source