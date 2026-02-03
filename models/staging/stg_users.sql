/*
    Staging model for users with PII masking for GDPR compliance.

    PII Fields Masked:
    - name: Shows only first initial of each word (e.g., "Mr. Anthony Hale" → "M*** A*** H***")
    - email: SHA256 hashed for pseudonymization

    Original PII is never exposed beyond the raw/bronze layer.
*/

WITH source AS (
    SELECT * FROM {{ source('postgres_public', 'users') }}
)

SELECT
    id AS user_id,

    -- Mask name: show first letter of EACH word (handles names with 2+ parts)
    REGEXP_REPLACE(name, '(\w)\w*', '\1***', 'g') AS name_masked,

    -- Hash email for pseudonymization (allows consistent joins if needed)
    ENCODE(SHA256(LOWER(email)::bytea), 'hex') AS email_hash,

    -- Keep non-PII metadata
    modified AS modified_at

FROM source