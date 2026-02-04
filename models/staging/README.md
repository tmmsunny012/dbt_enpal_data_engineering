# Staging Layer (Bronze)

This layer contains cleaned and standardized versions of raw source data from the Pipedrive CRM system.

## Purpose

- Clean and rename columns for consistency
- Apply data type casting
- **Mask PII for GDPR compliance**
- Document data quality issues

## Models

| Model | Source Table | Description |
|-------|--------------|-------------|
| `stg_stages` | `stages` | Sales funnel stage definitions with funnel step numbers |
| `stg_activity_types` | `activity_types` | Activity type lookup with cleaned boolean flags |
| `stg_activities` | `activity` | Sales activities linked to deals |
| `stg_deal_changes` | `deal_changes` | Historical changes to deals (stage transitions, owner changes) |
| `stg_users` | `users` | Sales team members with **PII masked** |
| `stg_fields` | `fields` | Field definitions with JSON value options |

## PII Masking (GDPR Compliance)

The `stg_users` model masks personally identifiable information:

| Original Field | Masking Method | Example |
|----------------|----------------|---------|
| `name` | First initials only | `John Smith` → `J*** S***` |
| `email` | SHA256 hash | `john@example.com` → `a8f5f167...` |

**Why?**
- Original PII never leaves the raw/bronze layer
- Hashed email allows consistent joins if needed
- Complies with GDPR data minimization principle

## Data Quality Notes

- **`stg_activities`**: Source data contains duplicate `activity_id` values (documented, not a bug in our code)

## Materialization

All staging models are materialized as **views** to:
- Reduce storage costs
- Always reflect current source data
- Speed up development iterations

## Tests

23 data tests validate:
- Primary key uniqueness (where applicable)
- Not null constraints on required fields
- Accepted values for categorical fields

Run tests with:
```bash
dbt test --select staging
```