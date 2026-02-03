# Enpal Data Engineering Challenge - Project Architecture & Analysis

This document provides a comprehensive overview of the data engineering project architecture, design decisions, data flow, and analytical components.

## 1. Project Overview & Workflow

The goal of this project is to build a robust, scalable data pipeline to analyze Pipedrive CRM data. The pipeline transforms raw sales data into actionable business insights regarding Funnel Conversion Rates and Sales Representative Performance.

**High-Level Workflow:**
1.  **Ingestion**: Raw data is loaded into PostgreSQL (simulated via seed data for this project).
2.  **Transformation (dbt)**: Data is cleaned, normalized, and modeled using a Medallion Architecture (Staging -> Intermediate -> Marts).
3.  **Analysis (Jupyter)**: Final business logic is verified and visualized using Python/Pandas/Seaborn.
4.  **Containerization (Docker)**: The entire stack (DB + dbt + Jupyter) runs in isolated containers for reproducibility.

### 1.1 Architecture Diagram

```text
┌───────────────────────────┐
│     Project Sources       │
│  (./data/*.csv seeds)     │
└─────────────┬─────────────┘
              │ 1. Ingestion (dbt seed)
              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          PostgreSQL Data Warehouse                      │
│                                                                         │
│   2. Staging Layer (Bronze)        3. Intermediate Layer (Silver)       │
│  ┌───────────────────────┐        ┌────────────────────────────┐        │
│  │ • Clean Column Names  │───────►│ • Funnel Logic Mapping     │───┐    │
│  │ • PII Masking (GDPR)  │        │ • Event/Time Calculations  │   │    │
│  └───────────────────────┘        └────────────────────────────┘   │    │
│                                                                    │    │
│                                                                    │    │
│   4. Marts Layer (Gold) <──────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ • One Big Table (OBT)                                           │    │
│  │ • Aggregated Monthly Rep Performance                            │    │
│  │ • Funnel Drop-off Rates                                         │    │
│  └──────────────────────────────┬──────────────────────────────────┘    │
└─────────────────────────────────┼───────────────────────────────────────┘
                                  │
                                  │ 5. Analysis & Reporting
                                  ▼
                        ┌─────────────────────┐
                        │  Jupyter Environment│
                        │  (Docker Container) │
                        │ ┌─────────────────┐ │
                        │ │ • Funnel Viz    │ │
                        │ │ • Rep Leaders   │ │
                        │ └─────────────────┘ │
                        └─────────────────────┘
```

---

## 2. Data Transformation Flow (Medallion Architecture)

We utilize a layered approach to ensure modularity, reusability, and data quality.

### 2.1 Staging Layer (Bronze)
**Goal:** Clean and normalize raw data 1:1.
*   **Key Actions:**
    *   Renaming columns to snake_case.
    *   Casting data types (Strings, Integers, Timestamps).
    *   **Normalization:** Lowercasing categorical fields (e.g., `stage_name`, `activity_type`) to handle messy manual entry.
    *   **PII Masking:** Hashing or masking sensitive user data (e.g., in `stg_users`).
*   **Models:** `stg_deals`, `stg_activities`, `stg_stages`, `stg_users`, `stg_deal_changes`.

### 2.2 Data Privacy & GDPR Compliance
Ensuring PII (Personally Identifiable Information) protection is critical for this project.

*   **Strategy:** Hashing/Masking at the earliest entry point (Staging Layer).
*   **Implementation:** In `stg_users.sql`, we mask the `name` column using a hashing algorithm or partial obscuring.
    *   **Original:** `John Doe`
    *   **Masked:** `J*******` or `23a9d...` (SHA256 hash).
*   **Benefit:** Developers and analysts work with identifying keys (`user_id`) without being exposed to raw names or emails, ensuring GDPR compliance by design.

### 2.3 Intermediate Layer (Silver)
**Goal:** Compute complex business logic and isolate joins.
*   **Key Actions:**
    *   **Funnel Mapping:** Mapping raw stages/activities to standardized funnel steps.
    *   **Event Handling:** Calculating previous stages and dwell times.
*   **Models:**
    *   `int_deal_activities`: Cleaning activity types mapping them to funnel steps (e.g., 'meeting' -> 'Sales Call 1').
    *   `int_deal_stage_transitions`: Tracking historical movement of deals through pipeline stages using window functions (`LAG`).
    *   `int_deal_losses`: Isolating lost deals for churn analysis.

### 2.4 Marts Layer (Gold)
**Goal:** Production-ready tables for BI tools and Analysts.
*   **Key Actions:**
    *   Aggregation by Month and Sales Rep.
    *   Denormalization (One Big Table approach) for easier consumption.
*   **Models:**
    *   `rep_sales_funnel_monthly`: Monthly aggregate of deal volume per funnel step.
    *   `rep_sales_rep_performance_monthly`: "Leaderboard" style table showing activities and deals worked per rep.

### 2.5 Detailed Logic Diagram (ASCII)

```text
[Stage Transitions Flow]                 [Activities Flow]
       │                                        │
deal_changes (event log)                 activity (raw)
       │                                        │
       ▼                                        ▼
stg_deal_changes                         stg_activities
(Filter: field='stage_id')               (Filter: type IN 'meeting','sc_2')
       │                                        │
       ▼                                        ▼
int_deal_stage_transitions               int_deal_activities
(Window: LAG/Lead Time)                  (Dedupe: MIN(due_to))
       │                                        │
       ▼                                        ▼
int_deal_funnel_entries                  int_deal_funnel_entries
(Map: stage_id -> 1,2,3..)               (Map: type -> 2.1, 3.1)
       │                                        │
       └──────────────────┬─────────────────────┘
                          │
                          ▼
                 Union All Streams
                          │
                          ▼
            Join stg_stages (Get KPI Names)
                          │
                          ▼
            rep_sales_funnel_monthly (Mart)
            (Group By: Month, KPI, Step)
```

---

## 3. Business Logic: Sales Funnel Mapping

The core complexity of this project lies in mapping disparate CRM states to a linear sales funnel.

| Funnel Step | Logic Source | Definition |
| :--- | :--- | :--- |
| **1. Lead Gen** | `stg_stages` | Stage: 'Lead Generation' |
| **2. Qualified** | `stg_stages` | Stage: 'Qualified Lead' |
| **2.1 Sales Call 1** | `stg_activities` | Activity Type: 'Meeting' (normalized from 'meeting', 'Meeting') |
| **3. Needs Analysis** | `stg_stages` | Stage: 'Needs Assessment' |
| **3.1 Sales Call 2** | `stg_activities` | Activity Type: 'SC_2' (normalized from 'sc_2', 'SC-2') |
| **4. Proposal** | `stg_stages` | Stage: 'Proposal/Quote Preparation' |
| **5. Negotiation** | `stg_stages` | Stage: 'Negotiation' |
| **6. Closing** | `stg_stages` | Stage: 'Closing' |
| **Lost** | `stg_deals` | Status: 'lost' |

**Design Note:** Activities (Events) and Stages (States) are unified into a single reporting structure in the Analysis layer notebooks to provide a holistic view.

---

## 4. Key Design Decisions

### 4.1 OBT (One Big Table) vs. Star Schema
*   **Decision:** We opted for **One Big Table (OBT)** in the Marts layer.
*   **Why?**
    *   **Usability:** Analysts can query `rep_sales_rep_performance_monthly` directly without writing complex `JOIN` logic.
    *   **Scale:** For CRM data volumes (typically <100GB), OBT performance is excellent on modern columnar warehouses.
    *   **Simplicity:** Reduces the cognitive load for end-users.

### 4.2 Case-Insensitive Matching
*   **Problem:** User-entered data in CRM is messy (e.g., "Meeting", "meeting", "MEETING").
*   **Solution:** All join keys and categorical filters are wrapped in `LOWER()` in the Staging layer to ensure robust matching downstream.

---

## 5. Data Quality & Testing

We implement a rigorous testing strategy to ensuring trust in the data.

### 5.1 Automated Tests (dbt)
We define tests in `_schema.yml` files attached to every model.
*   **Uniqueness:** Primary keys (`deal_id`, `activity_id`) must be unique.
*   **Not Null:** Critical foreign keys and timestamps must allow be present.
*   **Referential Integrity:** `deal_id` in activities must exist in `stg_deals`.
*   **Accepted Values:** `status` must be one of `['won', 'lost', 'open']`.

### 5.2 SQL Data Quality Score Methodology
To quantify data quality, we can run "audit" queries that check for "dirty" data ratios.

**Example DQ Audit Query:**
```sql
-- Calculate % of Activities with Missing or Invalid Deal Links
WITH audit AS (
    SELECT 
        COUNT(*) as total_rows,
        COUNT(CASE WHEN deal_id IS NULL THEN 1 END) as orphan_activities,
        COUNT(CASE WHEN lower(type) NOT IN ('call', 'meeting', 'email', 'sc_2') THEN 1 END) as unknown_types
    FROM {{ ref('stg_activities') }}
)
SELECT 
    total_rows,
    100.0 * (1 - (orphan_activities::numeric / total_rows)) as completeness_score,
    100.0 * (1 - (unknown_types::numeric / total_rows)) as consistency_score
FROM audit;
```

---

## 6. Performance & Scalability Analysis

### 6.1 Current Performance
*   **Volume:** Small (Seed Data).
*   **Bottlenecks:** None efficiently running on Postgres.
*   **Optimization:** Staging layer handles heavy casting upfront, leaving Marts to do simple aggregations.

### 6.2 Scaling Strategy (Future)
If data volume grows to 10M+ rows:
1.  **Incremental Materialization:** Convert `marts` models to `materialized='incremental'` to only process new/changed records.
2.  **Partitioning:** Partition tables by `created_at` or `month` in the Data Warehouse (e.g., Snowflake/BigQuery) to prune scans.
3.  **Snapshotting:** Implement `dbt snapshots` for `deals` table to track "Slowly Changing Dimensions" (SCD Type 2) if history logs (`deal_changes`) become unreliable.

---

## 7. Analysis Layer & Visualizations

We use **Jupyter Notebooks** running in Docker for the final mile analysis.
*   **`exploratory_analysis.ipynb`**: inspecting raw data distributions, checking for duplicates, and validating seed data assumptions.
*   **`model_analysis.ipynb`**: Visualizing the output of dbt Marts.

### 7.1 Sample Analytical Queries
These are the key SQL queries an analyst would run on the final Marts.

**A. Sales Rep Leaderboard (Weighted by Activity)**
```sql
SELECT 
    sales_rep_name,
    deals_worked,
    activities_completed,
    -- Simple Efficiency Metric: Activities per Deal
    ROUND(activities_completed::numeric / NULLIF(deals_worked, 0), 1) as avg_effort_per_deal
FROM {{ ref('rep_sales_rep_performance_monthly') }}
ORDER BY activities_completed DESC
LIMIT 10;
```

**B. Funnel Drop-off Analysis**
```sql
SELECT 
    funnel_step, 
    kpi_name,
    SUM(deals_count) as total_volume,
    -- Calculate Step-over-Step Retention
    ROUND(100.0 * SUM(deals_count) / LAG(SUM(deals_count)) OVER (ORDER BY funnel_step), 1) as retention_rate_pct
FROM {{ ref('rep_sales_funnel_monthly') }}
WHERE funnel_step NOT IN ('Lost') 
GROUP BY 1, 2
ORDER BY 1;
```

---

## 8. Future Considerations (Roadmap)

1.  **Orchestration:** Deploy Airflow or Dagster to schedule `dbt run` daily.
2.  **CI/CD:** Implement GitHub Actions to run `dbt test` on every Pull Request.
3.  **Data Observability:** Integrate a tool like `re_data` or `Elementary` to track data freshness and volume anomalies automatically.
4.  **Reverse ETL:** Feed the calculated "Hot Leads" back into Pipedrive CRM for the sales team to act on.
