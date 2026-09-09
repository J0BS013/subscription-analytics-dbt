{{ config(materialized='table') }}

WITH customer_cohorts AS (
  SELECT
    customer_id,
    DATE_TRUNC('month', MIN(subscription_start_date)) AS cohort_month
  FROM {{ ref('fct_subscriptions') }}
  GROUP BY 1
),
cohort_sizes AS (
  SELECT cohort_month, COUNT(*) AS cohort_size
  FROM customer_cohorts
  GROUP BY 1
),
activity AS (
  SELECT
    cohorts.cohort_month,
    customer_activity.activity_month,
    DATE_DIFF('month', cohorts.cohort_month, customer_activity.activity_month) AS period_number,
    COUNT(DISTINCT customer_activity.customer_id) AS active_customers
  FROM customer_cohorts AS cohorts
  INNER JOIN {{ ref('int_customer_activity_monthly') }} AS customer_activity
    ON cohorts.customer_id = customer_activity.customer_id
    AND customer_activity.activity_month >= cohorts.cohort_month
  GROUP BY 1, 2, 3
)
SELECT
  activity.cohort_month,
  activity.activity_month,
  activity.period_number,
  sizes.cohort_size,
  activity.active_customers,
  ROUND(activity.active_customers * 100.0 / sizes.cohort_size, 2) AS retention_rate_pct
FROM activity
INNER JOIN cohort_sizes AS sizes
  ON activity.cohort_month = sizes.cohort_month
ORDER BY 1, 2
