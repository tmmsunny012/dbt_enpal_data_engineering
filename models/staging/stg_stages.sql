/*
    Staging model: Deal stages from Pipedrive CRM.

    Purpose:
    - Lookup table for deal pipeline stages
    - Maps stage names to funnel step numbers for reporting
    - Standardizes stage ordering

    Grain: One row per stage_id

    Business Context:
    - Pipedrive stages represent the sales pipeline
    - Each stage maps to a numbered funnel step (1-9)
    - Funnel also includes sub-steps 2.1 and 3.1 (from activities, not stages)
    - Deals progress sequentially through stages (though can skip or move backward)
*/

WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'stages') }}
)

SELECT
    -- Primary key
    stage_id,

    -- Stage name
    stage_name,

    -- Map stage names to funnel step numbers (stored as text for consistency)
    -- Normalizing stage_name to lower case for robust matching
    -- regardless of input casing variations (e.g., "Lead Generation" vs "lead generation")
    -- Used for ordering and filtering in funnel reports
    CASE LOWER(stage_name)
        WHEN 'lead generation' THEN '1'
        WHEN 'qualified lead' THEN '2'
        WHEN 'needs assessment' THEN '3'
        WHEN 'proposal/quote preparation' THEN '4'
        WHEN 'negotiation' THEN '5'
        WHEN 'closing' THEN '6'
        WHEN 'implementation/onboarding' THEN '7'
        WHEN 'follow-up/customer success' THEN '8'
        WHEN 'renewal/expansion' THEN '9'
    END AS funnel_step

FROM source