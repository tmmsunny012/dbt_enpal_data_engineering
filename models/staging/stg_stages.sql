WITH source AS (
    SELECT * FROM {{ source('pg_pipedrive_crm', 'stages') }}
)

SELECT
    stage_id,
    stage_name,

    -- Add funnel step number for ordering
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