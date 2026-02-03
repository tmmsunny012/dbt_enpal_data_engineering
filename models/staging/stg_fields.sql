/*
    Staging model: Field definitions and metadata from Pipedrive CRM.

    Purpose:
    - Provides metadata about custom fields in Pipedrive
    - Contains dropdown/picklist options for fields like lost_reason
    - Lookup dimension for parsing field values

    Grain: One row per field definition

    Business Context:
    - field_value_options contains JSON with option IDs and labels
    - Used to map numeric IDs (e.g., lost_reason = 3) to labels ("Unreachable Customer")
    - Not all fields have options - only dropdown/picklist fields
*/

WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'fields') }}
)

SELECT
    -- Primary key
    id AS field_id,

    -- Field identifiers
    field_key,  -- Machine-readable field identifier (e.g., 'lost_reason')
    name AS field_name,  -- Human-readable field name

    -- Dropdown options (JSON format)
    -- Example: [{"id":1,"label":"Customer Not Ready"},{"id":2,"label":"Pricing Issues"}]
    field_value_options

FROM source