{{ config(materialized='table') }}

SELECT
  subscription_id,
  customer_id,
  plan_id,
  subscription_start_date,
  subscription_cancelled_date,
  monthly_mrr_usd,
  CASE WHEN subscription_cancelled_date IS NULL THEN TRUE ELSE FALSE END AS is_active
FROM {{ ref('int_subscription_periods') }}
