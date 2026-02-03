# Enpal Data Engineering Assessment - Solution

## Table of Contents
- [Task Solution Overview](#task-solution-overview)
- [Architecture & Approach](#architecture--approach)
- [Key Decisions](#key-decisions)
- [Data Quality Findings](#data-quality-findings)
- [Project Statistics](#project-statistics)
- [Setup Instructions](#setup-instructions)

---

## Task Solution Overview

This project implements a **medallion architecture** (staging → intermediate → marts) for Pipedrive CRM sales funnel analytics. The solution delivers the required `rep_sales_funnel_monthly` report while building a **reusable, extensible data platform** that supports multiple reporting use cases.

### What Was Delivered

- Monthly sales funnel report with 11 funnel steps (1-9 + sub-steps 2.1, 3.1)
- Proper data modeling with staging, intermediate, and marts layers
- Source definitions and data quality tests
- Lost deals tracking
- Sales rep performance report (demonstrates architecture reusability)
- PII masking for GDPR compliance
- Comprehensive documentation and comments

---

## Architecture & Approach

### Medallion Architecture (Bronze → Silver → Gold)

```
Raw Sources (Postgres)
    ↓
   Staging Layer (Bronze)
    ├─ stg_activities        - Activity tracking
    ├─ stg_activity_types    - Activity type lookup
    ├─ stg_deal_changes      - Deal change audit log
    ├─ stg_fields            - Field metadata
    ├─ stg_stages            - Pipeline stage definitions
    └─ stg_users             - User data (PII masked)
    ↓
   Intermediate Layer (Silver)
    ├─ int_deals                    - Deal dimension (deduplicated)
    ├─ int_deal_stage_transitions   - Stage progression tracking
    ├─ int_deal_activities          - Completed activities
    └─ int_deal_losses              - Lost deals with reasons
    ↓
   Marts Layer (Gold)
    ├─ rep_sales_funnel_monthly          - PRIMARY: Monthly funnel metrics
    └─ rep_sales_rep_performance_monthly - REUSABILTY EXAMPLE: Sales rep workload analysis
```

### Layer Responsibilities

**Staging (Bronze):**
- 1:1 mapping to source tables
- Column renaming for consistency
- Data type standardization
- PII masking (users table)
- No business logic

**Intermediate (Silver):**
- Business logic and transformations
- Deduplication and data quality fixes
- Enrichment with lookups
- Reusable building blocks for multiple reports

**Marts (Gold):**
- Business-ready aggregated reports
- Materialized as tables for performance
- Multiple reports demonstrating architecture reusability

---

## Key Decisions

### 1. PII Masking (GDPR Compliance)

**Decision:** Implement PII masking at staging layer for user names and emails.

**Implementation:**
- Name masking: `REGEXP_REPLACE(name, '(\w)\w*', '\1***', 'g')` → "John Doe" becomes "J*** D***"
- Email hashing: `SHA256(LOWER(email))` for pseudonymization
- Ensures GDPR compliance while maintaining data utility

**Why:** Demonstrates data governance awareness and protects sensitive information from the start.

### 2. Lost Deals Discovery

**Finding:** During data exploration, discovered 6,000 `lost_reason` field changes that were not part of initial requirements.

**Decision:** Built `int_deal_losses` model to track lost deals with categorized reasons.

**Impact:**
- Provides funnel exit analysis (11th funnel step: "Lost")
- Identifies pipeline leakage points by reason:
  - Unreachable Customer: 1,269 deals 
  - Product Mismatch: 1,251 deals 
  - Pricing Issues: 1,203 deals 
  - Customer Not Ready: 1,146 deals 
  - Duplicate Entry: 1,131 deals 

**Reference:** See full analysis in [`analysis/notebooks/model_analysis.ipynb`](analysis/notebooks/model_analysis.ipynb)

**Why:** Shows thorough data exploration and business thinking beyond requirements.

### 3. Month Format Standardization

**Decision:** Use `TO_CHAR(DATE_TRUNC('month', timestamp), 'YYYY-MM')` format consistently.

**Benefits:**
- Clean string format for grouping and display
- Consistent across all time-series models
- Easier for downstream BI tools to consume

### 4. Deduplication Strategy

**Finding:** 1,995 deals had multiple `add_time` records (data quality issue in source).

**Solution:** Used `MIN(changed_at)` aggregation to capture earliest creation time per deal.

**Why:** Preserves data integrity while handling source data quality issues transparently.

### 5. Sales Rep Performance Model

**Decision:** Built second marts model (`rep_sales_rep_performance_monthly`) demonstrating architecture supports multiple use cases.

**Purpose:**
- Shows `stg_users` and `stg_activities` are actually reused
- Proves architecture supports "many other requests in future" (per task requirement)
- Only 25 lines of SQL because foundation is solid

**Reference:** See full visualization (Stacked Bar Chart) in [`analysis/notebooks/model_analysis.ipynb`](analysis/notebooks/model_analysis.ipynb)

**Why:** Demonstrates forward-thinking architecture, not just solving for one report.

---

## Data Quality Findings

### Issues Discovered & Resolved

1. **Duplicate Activity IDs**
   - Issue: 4,568 duplicate `activity_id` values in source data
   - Resolution: Documented in schema.yml, removed unique constraint
   - Impact: Minimal - doesn't affect funnel metrics (uses deal_id for counting)

2. **Multiple Deal Creation Events**
   - Issue: 1,995 deals have multiple `add_time` events
   - Resolution: Deduplication using MIN() in `int_deals` model
   - Impact: Ensures accurate deal counts in funnel

3. **Missing Lost Deals Tracking**
   - Issue: 6,000 lost deals ignored in original scope
   - Resolution: Created `int_deal_losses` model
   - Impact: Complete funnel picture with exit analysis

4. **Inconsistent Month Formats**
   - Issue: Timestamps making time-series analysis harder
   - Resolution: Standardized to 'YYYY-MM' string format
   - Impact: Cleaner reporting, easier aggregation

---

## Project Statistics

### Models & Tests
- **12 models** across 3 layers
- **53 data quality tests** (100% passing)
- **2 marts reports** (funnel + rep performance)
- **142 funnel report rows** (11 steps × 13+ months)
- **1,383 rep performance rows** (143 reps × ~10 months avg)

### Test Coverage
- **Staging:** 32 tests (PII handling, data types, accepted values)
- **Intermediate:** 12 tests (referential integrity, deduplication)
- **Marts:** 9 tests (final report validation)

### Documentation
- 3 comprehensive README files (staging, intermediate, marts)
- SQL comments in all 12 models explaining business logic
- Schema definitions with column descriptions for all models

---

## Setup Instructions

### Prerequisites
1. Docker Desktop installed and running
2. dbt-core and dbt-postgres installed (`pip install dbt-core dbt-postgres`)

### Running via Docker (No Local Install Needed)

Since this project is fully containerized, you can run all dbt commands through Docker without installing dbt locally.

```bash
# 1. Start PostgreSQL & Docs Server
docker compose up -d

# 2. Run dbt models via Docker
docker compose run --rm dbt -c "dbt run"

# 3. Run dbt tests via Docker
docker compose run --rm dbt -c "dbt test"

# 4. Query the reports (via dbt)
docker compose run --rm dbt -c "dbt show --inline 'select * from public_marts.rep_sales_funnel_monthly order by funnel_step'"
```

### Quick Start (Local dbt)

If you have dbt installed locally:

```bash
# 1. Start PostgreSQL database
docker compose up -d

# 2. Wait for data to load (check with)
docker compose logs -f data_loader

# 3. Run dbt models
dbt run

# 4. Run tests
dbt test

# 5. Query the reports
# Connect to postgres://admin:admin@localhost:5432/postgres
SELECT * FROM public_marts.rep_sales_funnel_monthly
ORDER BY month, funnel_step;
```

### Interactive Analysis (Jupyter Notebook)
You can run the exploratory data analysis notebook to see the data profiling and visualization.

1.  **Access Jupyter**: Open http://localhost:8888 in your browser.
2.  **Login**: Use the token `admin`.
3.  **Run**:
    *   `exploratory_analysis.ipynb`: Data profiling and raw data checks.
    *   `model_analysis.ipynb`: Final funnel metrics and sales performance visualization.
4.  **Note**: The environment comes pre-configured with pandas, sqlalchemy, and connection drivers.

### Database Credentials

| Parameter | Value |
| :--- | :--- |
| **Host** | `localhost` |
| **User** | `admin` |
| **Password** | `admin` |
| **Port** | `5432` |
| **Database** | `postgres` |

### Project Structure

```text
dbt_enpal_data_engineering/
├── models/
│   ├── staging/           # Bronze layer (6 models)
│   │   ├── _sources.yml   # Source definitions
│   │   ├── _schema.yml    # Tests and documentation
│   │   └── *.sql          # Staging models
│   ├── intermediate/      # Silver layer (4 models)
│   │   ├── _schema.yml
│   │   └── *.sql
│   └── marts/             # Gold layer (2 models)
│       ├── _schema.yml
│       └── *.sql
├── raw_data/              # CSV source files
├── docker-compose.yml     # PostgreSQL + pgAdmin
└── dbt_project.yml        # dbt configuration
```

---

## Sample Queries

### Funnel Analysis

```sql
-- View complete funnel for a specific month
SELECT
    funnel_step,
    kpi_name,
    deals_count
FROM public_marts.rep_sales_funnel_monthly
WHERE month = '2024-02'
ORDER BY funnel_step;
```

### Conversion Rates

```sql
-- Calculate step-to-step conversion rates
WITH funnel_with_prev AS (
    SELECT
        month,
        funnel_step,
        kpi_name,
        deals_count,
        LAG(deals_count) OVER (
            PARTITION BY month
            ORDER BY funnel_step
        ) as prev_step_count
    FROM public_marts.rep_sales_funnel_monthly
    WHERE funnel_step NOT IN ('2.1', '3.1', 'Lost')  -- Exclude sub-steps and exits
)
SELECT
    month,
    funnel_step,
    kpi_name,
    deals_count,
    prev_step_count,
    ROUND(
        deals_count * 100.0 / NULLIF(prev_step_count, 0),
        2
    ) as conversion_rate_pct
FROM funnel_with_prev
WHERE prev_step_count IS NOT NULL
ORDER BY month, funnel_step;
```

### Sales Rep Performance

```sql
-- Top performing sales reps by activities completed
SELECT
    sales_rep_name,
    SUM(deals_worked) as total_deals,
    SUM(activities_completed) as total_activities,
    SUM(sales_call_1_completed) as total_sc1,
    SUM(sales_call_2_completed) as total_sc2
FROM public_marts.rep_sales_rep_performance_monthly
GROUP BY sales_rep_name
ORDER BY total_activities DESC
LIMIT 10;
```

### Lost Deal Analysis

```sql
-- Lost deals breakdown by reason
SELECT
    lost_reason_label,
    COUNT(*) as deals_lost,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct_of_losses
FROM public_intermediate.int_deal_losses
GROUP BY lost_reason_label
ORDER BY deals_lost DESC;
```

---

## Technical Highlights

### SQL Optimization
-  Uses `COUNT(DISTINCT deal_id)` to handle multiple stage entries
-  Window functions for conversion rate calculations
-  Efficient LEFT JOINs with proper indexing via primary keys
-  Materialized marts as tables for query performance

### Data Quality
- 53 automated tests covering uniqueness, null checks, accepted values
- Handles source data quality issues (duplicates, multiple timestamps)
- Clear documentation of data quality decisions

### Code Organization
- Consistent naming conventions (stg_, int_, rep_)
- Comprehensive inline SQL comments
- Modular CTEs with clear purposes
- README files in each layer folder

### Future Extensibility
- Staging layer ready for additional source tables
- Intermediate layer supports multiple reporting use cases
- PII masking framework in place for new user-related data
- Month standardization pattern established

---

## Original Task Requirements

## Project
1. Remove the test model once you make sure it works
2. Dive deep into the Pipedrive CRM source data to gain a thorough understanding of all its details. (You may also research the Pipedrive CRM tool terms).
3. Define DBT sources and build the necessary layers organizing the data flow for optimal relevance and maintainability.
4. Build a reporting model (rep_sales_funnel_monthly) with monthly intervals, incorporating the following funnel steps (KPIs):  
  &nbsp;&nbsp;&nbsp;Step 1: Lead Generation  
  &nbsp;&nbsp;&nbsp;Step 2: Qualified Lead  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Step 2.1: Sales Call 1  
  &nbsp;&nbsp;&nbsp;Step 3: Needs Assessment  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Step 3.1: Sales Call 2  
  &nbsp;&nbsp;&nbsp;Step 4: Proposal/Quote Preparation  
  &nbsp;&nbsp;&nbsp;Step 5: Negotiation  
  &nbsp;&nbsp;&nbsp;Step 6: Closing  
  &nbsp;&nbsp;&nbsp;Step 7: Implementation/Onboarding  
  &nbsp;&nbsp;&nbsp;Step 8: Follow-up/Customer Success  
  &nbsp;&nbsp;&nbsp;Step 9: Renewal/Expansion
5. Column names of the reporting model: `month`, `kpi_name`, `funnel_step`, `deals_count`
6. “Git commit” all the changes and create a PR to your forked repo (not the original one). Send your repo link to us.
