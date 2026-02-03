# Marts Layer (Gold)

This layer contains final reporting models ready for business consumption.

## Purpose

- Provide business-ready datasets
- Aggregate data for reporting and analytics
- Serve as the interface for BI tools and dashboards

## Models

| Model | Description | Output |
|-------|-------------|--------|
| `rep_sales_funnel_monthly` | Monthly sales funnel metrics | 128 rows (as of current data) |

## rep_sales_funnel_monthly

### Description

Tracks deal counts through each step of the sales funnel by month.

### Output Schema

| Column | Type | Description |
|--------|------|-------------|
| `month` | timestamp | First day of the month |
| `kpi_name` | string | Name of the funnel step |
| `funnel_step` | string | Step number (1, 2, 2.1, 3, 3.1, 4-9) |
| `deals_count` | integer | Count of unique deals |

### Funnel Steps

| Step | KPI Name | Source |
|------|----------|--------|
| 1 | Lead Generation | Stage transition |
| 2 | Qualified Lead | Stage transition |
| 2.1 | Sales Call 1 | Activity completion |
| 3 | Needs Assessment | Stage transition |
| 3.1 | Sales Call 2 | Activity completion |
| 4 | Proposal/Quote Preparation | Stage transition |
| 5 | Negotiation | Stage transition |
| 6 | Closing | Stage transition |
| 7 | Implementation/Onboarding | Stage transition |
| 8 | Follow-up/Customer Success | Stage transition |
| 9 | Renewal/Expansion | Stage transition |

### Data Flow

```
int_deal_stage_transitions ──┐
                             ├──► rep_sales_funnel_monthly
int_deal_activities ─────────┘
```

### Sample Output

```
| month      | kpi_name        | funnel_step | deals_count |
|------------|-----------------|-------------|-------------|
| 2024-01-01 | Lead Generation | 1           | 30          |
| 2024-01-01 | Qualified lead  | 2           | 6           |
| 2024-01-01 | Sales Call 1    | 2.1         | 77          |
| 2024-02-01 | Lead Generation | 1           | 194         |
```

## Materialization

Marts models are materialized as **tables** to:
- Optimize query performance for end users
- Provide stable snapshots for reporting
- Reduce load on underlying views

## Tests

5 data tests validate:
- Not null constraints on all columns
- Accepted values for `funnel_step` (1-9 and sub-steps)

Run tests with:
```bash
dbt test --select marts
```

## Usage

Query the report directly:
```sql
SELECT * FROM public_marts.rep_sales_funnel_monthly
ORDER BY month, funnel_step;
```

Or filter by month:
```sql
SELECT * FROM public_marts.rep_sales_funnel_monthly
WHERE month = '2024-03-01'
ORDER BY funnel_step;
```
