/*
    Staging model: Activities from Pipedrive CRM.

    Purpose:
    - Cleans and standardizes raw activity data
    - Renames columns for consistency
    - One row per activity (calls, meetings, follow-ups, etc.)

    Grain: One row per activity_id

    Business Context:
    - Activities track sales rep actions on deals
    - Used to identify completion of Sales Call 1 and Sales Call 2
    - Critical for funnel sub-steps 2.1 and 3.1
*/

WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'activity') }}
)

SELECT
    -- Primary key
    activity_id,

    -- Foreign keys
    type AS activity_type_code,  -- Links to activity_types
    assigned_to_user AS user_id,  -- Links to users
    deal_id,  -- Links to deals

    -- Activity metadata
    done AS is_completed,  -- Whether activity was marked as done
    due_to AS due_at  -- When activity was scheduled/completed

FROM source