/*
    Staging model: Activity types lookup table from Pipedrive CRM.

    Purpose:
    - Provides human-readable names for activity type codes
    - Standardizes active flag as boolean
    - Lookup dimension for activities

    Grain: One row per activity_type_id

    Business Context:
    - 'meeting' = Sales Call 1 (funnel step 2.1)
    - 'sc_2' = Sales Call 2 (funnel step 3.1)
    - Other types: follow_up, after_close_call
*/

WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'activity_types') }}
)

SELECT
    -- Primary key
    id AS activity_type_id,

    -- Descriptive attributes
    name AS activity_type_name,  -- Human-readable label
    type AS activity_type_code,  -- Code used in activities table

    -- Convert string flag to boolean for easier querying
    -- Source data has 'True'/'False' as strings (per init.sql VARCHAR(10))
    CASE WHEN LOWER(active) IN ('true', 'yes', '1') THEN TRUE ELSE FALSE END AS is_active

FROM source