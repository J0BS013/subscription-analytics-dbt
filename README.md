# Subscription Analytics with dbt and DuckDB

A small, reproducible dbt project for subscription churn and retention analysis. It runs locally on DuckDB using versioned seed data.

## What it demonstrates

- Cohort retention with a fixed cohort denominator.
- Subscription lifecycle and churn by plan and signup month.
- dbt schema tests plus a semantic regression test for retention.
- Reproducible local execution without external credentials.

## Quick start

```bash
python -m pip install -r requirements.txt
dbt build --project-dir streaming_project --profiles-dir .
dbt snapshot --project-dir streaming_project --profiles-dir .
```

The build loads the CSV seeds, materializes the models, and runs every test. The snapshot command captures SCD2 history for country and acquisition-channel changes. The generated local database is `streaming_project/streaming_data.duckdb`.

## Semantic regression check

The seed fixture contains two January 2024 subscribers. Only one is active in February, so the January cohort's month-one retention must be **50%**:

| cohort_month | period_number | cohort_size | active_users | retention_rate_pct |
|---|---:|---:|---:|---:|
| 2024-01-01 | 1 | 2 | 1 | 50.00 |

`streaming_project/tests/cohort_retention_denominator.sql` fails the dbt build if that result changes. Cohort size is calculated before activity joins and stays fixed across periods.

## Model grains

| Model | Grain |
|---|---|
| `cohort_analysis` | signup cohort month × activity month |
| `churn_analysis` | plan type × signup cohort month |

## Limitations and next steps

This is the corrected baseline, not yet the production flagship described in the portfolio SPEC. Incremental models, snapshots, contracts, semantic metrics, freshness, and CI are planned next.
