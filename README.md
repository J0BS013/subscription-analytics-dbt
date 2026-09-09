# Subscription Analytics with dbt and DuckDB

A reproducible, production-style dbt project for subscription analytics. It runs locally on DuckDB using versioned synthetic seed data and demonstrates reliable financial, retention, customer, and product analytics.

## What it demonstrates

- Cohort retention and NRR with fixed denominators.
- Subscription lifecycle, churn, MRR movements, and monthly revenue marts.
- Incremental product events, SCD Type 2 customer history, and enforced model contracts.
- dbt schema and semantic tests with reproducible CI on clean environments.

## Quick start

```bash
python -m pip install -r requirements.txt
dbt build --project-dir streaming_project --profiles-dir .
```

The build loads the CSV seeds, materializes the models, runs every test, and executes the customer snapshot. To capture a new SCD2 version after a customer-attribute correction, run `dbt snapshot --project-dir streaming_project --profiles-dir .` separately. The generated local database is `streaming_project/streaming_data.duckdb`.

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

## Architecture

```text
Versioned synthetic seeds
  -> sources + staging (typed, deduplicated)
  -> intermediate subscription periods / MRR movements / customer activity
  -> finance, customer, retention and product marts
  -> exposures: finance_dashboard and product_dashboard
```

## Production-oriented features

- `fct_product_events` is incremental, keyed by `product_event_id`, with a seven-day lookback for late arrivals.
- Product-event duplicates are deduplicated deterministically by latest `loaded_at`.
- `customers_snapshot` tracks SCD2 history for country and acquisition-channel changes.
- `fct_mrr_movements` enforces a dbt model contract.
- Macros centralize safe division and FX conversion.
- MRR supports new, expansion, contraction, churn and reactivation movements.
- NRR uses the fixed initial subscription cohort as its denominator.
- GitHub Actions loads the seeds and then runs `dbt build` on every pull request and push to `main`, reproducing the pipeline from a clean environment.

## Quality checks

Semantic tests verify the 50% cohort fixture, fixed cohort sizes, fixed NRR denominator, and full MRR bridge reconciliation. Generic tests cover keys, required fields, relationships and accepted movement values. CI validates all 76 dbt nodes: 10 seeds and 66 build nodes.

## Failure modes and recovery

If source data is late, rerun `dbt build`; the product-event model reprocesses the trailing seven days. If a source schema or contract changes, the build fails before downstream marts are promoted. For customer-attribute corrections, rerun `dbt snapshot` after the build to record a new SCD2 version. Generated DuckDB databases, logs and targets are ignored by Git.

## Documentation and benchmark

Generate local dbt lineage with:

```bash
dbt docs generate --project-dir streaming_project --profiles-dir .
dbt docs serve --project-dir streaming_project --profiles-dir .
```

See [the reproducible benchmark](docs/benchmark.md) for measured local results and limitations.
