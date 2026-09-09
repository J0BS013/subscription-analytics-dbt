-- Regression fixture: January 2024 has two subscribers, but only customer 1
-- is active in February. Retention must be 50%, never 100%.
WITH expected AS (
  SELECT
    CAST('2024-01-01' AS DATE) AS cohort_month,
    1 AS period_number,
    2 AS cohort_size,
    1 AS active_users,
    50.00 AS retention_rate_pct
),
actual AS (
  SELECT
    CAST(cohort_month AS DATE) AS cohort_month,
    period_number,
    cohort_size,
    active_users,
    retention_rate_pct
  FROM {{ ref('cohort_analysis') }}
)
SELECT 1 AS missing_or_incorrect_retention_fixture
WHERE NOT EXISTS (
  SELECT 1
  FROM actual
  INNER JOIN expected
    ON actual.cohort_month = expected.cohort_month
    AND actual.period_number = expected.period_number
    AND actual.cohort_size = expected.cohort_size
    AND actual.active_users = expected.active_users
    AND actual.retention_rate_pct = expected.retention_rate_pct
)
