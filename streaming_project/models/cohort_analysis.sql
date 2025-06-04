{{ config(materialized='view') }}


WITH user_cohorts AS (
  SELECT 
    user_id,
    DATE_TRUNC('month', signup_date) as cohort_month,
    signup_date
  FROM {{ ref('subscriptions') }}
),
user_activities AS (
  SELECT 
    e.user_id,
    DATE_TRUNC('month', e.event_date) as activity_month,
    MIN(e.event_date) as first_activity
  FROM {{ ref('events') }} e
  WHERE e.event_type != 'churn'
  GROUP BY 1, 2
),
cohort_data AS (
  SELECT 
    c.cohort_month,
    a.activity_month,
    DATE_DIFF('month', c.cohort_month, a.activity_month) as period_number,
    COUNT(DISTINCT c.user_id) as cohort_size,
    COUNT(DISTINCT a.user_id) as active_users
  FROM user_cohorts c
  LEFT JOIN user_activities a ON c.user_id = a.user_id
  GROUP BY 1, 2, 3
)
SELECT 
  cohort_month,
  period_number,
  cohort_size,
  active_users,
  ROUND(active_users * 100.0 / cohort_size, 2) as retention_rate_pct
FROM cohort_data
WHERE period_number IS NOT NULL
ORDER BY cohort_month, period_number
