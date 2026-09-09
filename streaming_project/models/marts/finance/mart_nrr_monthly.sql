{{ config(materialized='table') }}

WITH initial_cohort AS (
  SELECT subscription_id, subscription_start_date, monthly_mrr_usd
  FROM {{ ref('fct_subscriptions') }}
  WHERE DATE_TRUNC('month', subscription_start_date) = (
    SELECT MIN(DATE_TRUNC('month', subscription_start_date)) FROM {{ ref('fct_subscriptions') }}
  )
),
months AS (
  SELECT movement_month
  FROM {{ ref('mart_mrr_monthly') }}
),
cohort_mrr AS (
  SELECT
    months.movement_month,
    SUM(cohort.monthly_mrr_usd) + SUM(
      CASE
        WHEN movements.movement_month > DATE_TRUNC('month', cohort.subscription_start_date)
          THEN COALESCE(movements.mrr_delta_usd, 0)
        ELSE 0
      END
    ) AS current_cohort_mrr_usd
  FROM months
  CROSS JOIN initial_cohort AS cohort
  LEFT JOIN {{ ref('fct_mrr_movements') }} AS movements
    ON cohort.subscription_id = movements.subscription_id
    AND movements.movement_month <= months.movement_month
  GROUP BY 1
),
initial_mrr AS (
  SELECT SUM(monthly_mrr_usd) AS initial_cohort_mrr_usd FROM initial_cohort
)
SELECT
  cohort_mrr.movement_month,
  initial_mrr.initial_cohort_mrr_usd,
  cohort_mrr.current_cohort_mrr_usd,
  ROUND(100.0 * {{ safe_divide('cohort_mrr.current_cohort_mrr_usd', 'initial_mrr.initial_cohort_mrr_usd') }}, 2) AS nrr_pct
FROM cohort_mrr
CROSS JOIN initial_mrr
ORDER BY 1
