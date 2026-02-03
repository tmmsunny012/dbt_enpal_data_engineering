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
    -- Used for ordering and filtering in funnel reports
    CASE stage_name
        WHEN 'Lead Generation' THEN '1'
        WHEN 'Qualified lead' THEN '2'
        WHEN 'Needs Assessment' THEN '3'
        WHEN 'Proposal/Quote Preparation' THEN '4'
        WHEN 'Negotiation' THEN '5'
        WHEN 'Closing' THEN '6'
        WHEN 'Implementation/Onboarding' THEN '7'
        WHEN 'Follow-up/Customer Success' THEN '8'
        WHEN 'Renewal/Expansion' THEN '9'
    END AS funnel_step

FROM source