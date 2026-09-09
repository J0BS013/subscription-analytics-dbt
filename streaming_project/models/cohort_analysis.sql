{{ config(materialized='view') }}

WITH user_cohorts AS (
  SELECT
    user_id,
    DATE_TRUNC('month', signup_date) AS cohort_month
  FROM {{ ref('subscriptions') }}
),
cohort_sizes AS (
  SELECT
    cohort_month,
    COUNT(DISTINCT user_id) AS cohort_size
  FROM user_cohorts
  GROUP BY 1
),
user_activities AS (
  SELECT
    user_id,
    DATE_TRUNC('month', event_date) AS activity_month
  FROM {{ ref('events') }}
  WHERE event_type != 'churn'
  GROUP BY 1, 2
),
cohort_activity AS (
  SELECT
    cohorts.cohort_month,
    activities.activity_month,
    DATE_DIFF('month', cohorts.cohort_month, activities.activity_month) AS period_number,
    COUNT(DISTINCT activities.user_id) AS active_users
  FROM user_cohorts AS cohorts
  INNER JOIN user_activities AS activities
    ON cohorts.user_id = activities.user_id
    AND activities.activity_month >= cohorts.cohort_month
  GROUP BY 1, 2, 3
)
SELECT
  activity.cohort_month,
  activity.period_number,
  sizes.cohort_size,
  activity.active_users,
  ROUND(activity.active_users * 100.0 / sizes.cohort_size, 2) AS retention_rate_pct
FROM cohort_activity AS activity
INNER JOIN cohort_sizes AS sizes
  ON activity.cohort_month = sizes.cohort_month
ORDER BY 1, 2
