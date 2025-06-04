{{ config(materialized='view') }}

WITH subscriber_lifecycle AS (
  SELECT 
    s.user_id,
    s.plan_type,
    s.signup_date,
    s.cancel_date,
    COALESCE(s.cancel_date, CURRENT_DATE) as end_date,
    DATE_DIFF('day', s.signup_date, COALESCE(s.cancel_date, CURRENT_DATE)) as tenure_days,
    CASE WHEN s.cancel_date IS NOT NULL THEN 1 ELSE 0 END as churned
  FROM {{ ref('subscriptions') }} s
),
churn_analysis AS (
  SELECT 
    plan_type,
    DATE_TRUNC('month', signup_date) as cohort_month,
    COUNT(*) as total_subscribers,
    SUM(churned) as churned_subscribers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate_pct,
    ROUND(AVG(tenure_days), 0) as avg_tenure_days,
    ROUND(AVG(CASE WHEN churned = 1 THEN tenure_days END), 0) as avg_tenure_churned_days
  FROM subscriber_lifecycle
  GROUP BY 1, 2
)
SELECT * FROM churn_analysis