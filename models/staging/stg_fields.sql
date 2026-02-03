WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'fields') }}
)

SELECT
    id AS field_id,
    field_key,
    name AS field_name,
    field_value_options

FROM source