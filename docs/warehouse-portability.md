# Warehouse portability

The project is executable locally with dbt Core and DuckDB. The model layout,
tests, contracts, and metric contract are warehouse-agnostic; the adapter and a
small number of physical-design choices change in a managed warehouse.

| Concern | Local demo | Production adaptation |
|---|---|---|
| Adapter | `dbt-duckdb` | Use the appropriate dbt adapter for Snowflake, BigQuery, or Databricks. |
| Storage | One local DuckDB file | Configure database/catalog, schema, credentials, and environment-specific targets outside version control. |
| Incremental events | Seven-day `delete+insert` lookback | Keep the lookback policy, then use the warehouse-native incremental strategy and partition pruning. |
| Snapshot history | dbt snapshot table | Retain the same `customer_id` key and change-tracked attributes; schedule snapshots with the warehouse's orchestration platform. |
| Cost and performance | Smoke-sized fixtures | Cluster/partition by event or invoice date only after measuring workload-specific query patterns. |
| CI | DuckDB build in GitHub Actions | Use the same state-aware selection against a non-production CI schema, then defer unchanged relations to a protected production or staging environment. |

## Metric contract

`streaming_project/semantic_models/subscription_metrics.yml` is the versioned
semantic contract for MRR, revenue, NRR, and retention. It records the source
mart, grain, valid aggregation, time dimension, and definition for every
published metric. This prevents dashboards from independently redefining
denominators or summing month-end balances.

The contract is intentionally portable: a hosted dbt Semantic Layer, MetricFlow,
or a BI semantic model can ingest the same model and metric definitions when a
managed warehouse is introduced.

## Deliberate trade-offs

- DuckDB keeps setup small and reproducible; it is not presented as a
  substitute for a multi-user production warehouse.
- A full clean build remains required in CI because no persistent warehouse is
  available for relation deferral. The PR workflow also calculates the
  state-aware impacted graph, which is the selection to execute when a CI
  environment with deferred upstream relations is available.
- Monetary values and FX logic are limited to the supplied synthetic fixture.
  Production use requires audited exchange-rate sourcing and explicit revenue
  recognition policies.
