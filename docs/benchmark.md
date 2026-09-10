# Local benchmark

## Reproduce

```bash
python -m dbt.cli.main build --project-dir streaming_project --profiles-dir . --no-use-colors
```

## Measured result

On the local development environment, the complete build processed 10 seed files, 10 table models, 1 incremental model, 1 snapshot, 11 views, and 43 data tests in **5.33 seconds** (76 successful dbt nodes). This is a smoke-sized synthetic fixture, not a production-scale benchmark. Runtime will vary by machine and dependency-cache state.

## Trade-offs

- DuckDB makes the demo self-contained; production warehouses should use native partitioning/clustering and warehouse-specific cost controls.
- The seven-day lookback favors correctness for late product events over minimal incremental scanning.
- The incremental fixture demonstrates idempotent `delete+insert` behavior locally; it does not claim a measured performance result for billions of events.
