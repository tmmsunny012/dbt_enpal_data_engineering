# Intermediate Layer (Silver)

This layer contains business logic transformations that prepare data for reporting.

## Purpose

- Apply business rules and logic
- Join and aggregate staging models
- Create reusable intermediate datasets
- Handle data quality issues (deduplication, etc.)

## Models

| Model | Description | Key Logic |
|-------|-------------|-----------|
| `int_deals` | One row per deal with creation metadata | Deduplicated by earliest `add_time` |
| `int_deal_stage_transitions` | Deal stage transitions with stage metadata | Joins with `stg_stages` for funnel info |
| `int_deal_activities` | Completed sales activities per deal | Filters for Sales Call 1 & 2 only |

## Data Flow

```
stg_deal_changes ──► int_deals
                 ──► int_deal_stage_transitions ◄── stg_stages

stg_activities ──► int_deal_activities ◄── stg_activity_types
```

## Business Logic

### int_deals
- Source: `stg_deal_changes` where `changed_field_key = 'add_time'`
- Deduplication: Takes `MIN(changed_at)` per deal (handles multiple creation records)
- Output: One row per deal with `deal_id`, `created_at`, `created_month`

### int_deal_stage_transitions
- Source: `stg_deal_changes` where `changed_field_key = 'stage_id'`
- Enrichment: Joins with `stg_stages` to get `stage_name` and `funnel_step`
- Output: Every stage transition with timestamp and stage metadata

### int_deal_activities
- Source: `stg_activities` where `is_completed = 'true'`
- Filters: Only `meeting` (Sales Call 1) and `sc_2` (Sales Call 2) activities
- Enrichment: Maps activity types to funnel sub-steps (2.1 and 3.1)

## Materialization

All intermediate models are materialized as **views** to:
- Avoid data duplication
- Always reflect current staging data
- Enable quick iteration during development

## Tests

11 data tests validate:
- Not null constraints on key fields
- Unique deal_id in `int_deals`
- Accepted values for activity types and funnel names

Run tests with:
```bash
dbt test --select intermediate
```
