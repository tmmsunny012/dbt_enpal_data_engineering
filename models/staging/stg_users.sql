/*
    Staging model for users with PII masking for GDPR compliance.

    PII Fields Masked:
    - name: Shows only first initials (e.g., "John Smith" → "J*** S***")
    - email: SHA256 hashed for pseudonymization

    Original PII is never exposed beyond the raw/bronze layer.
*/

WITH source AS (
    SELECT * FROM {{ source('postgres_public', 'users') }}
)

SELECT
    id AS user_id,

    -- Mask name: show first letter of each word only
    CONCAT(
        LEFT(SPLIT_PART(name, ' ', 1), 1), '***',
        CASE
            WHEN SPLIT_PART(name, ' ', 2) != ''
            THEN CONCAT(' ', LEFT(SPLIT_PART(name, ' ', 2), 1), '***')
            ELSE ''
        END
    ) AS name_masked,

    -- Hash email for pseudonymization (allows consistent joins if needed)
    ENCODE(SHA256(LOWER(email)::bytea), 'hex') AS email_hash,

    -- Keep non-PII metadata
    modified AS modified_at

FROM source