{{ config(materialized='table') }}

WITH monthly_movements AS (
  SELECT
    movement_month,
    SUM(CASE WHEN movement_type = 'new' THEN mrr_delta_usd ELSE 0 END) AS new_mrr_usd,
    SUM(CASE WHEN movement_type = 'reactivation' THEN mrr_delta_usd ELSE 0 END) AS reactivation_mrr_usd,
    SUM(CASE WHEN movement_type = 'churn' THEN mrr_delta_usd ELSE 0 END) AS churn_mrr_usd,
    SUM(mrr_delta_usd) AS net_mrr_change_usd
  FROM {{ ref('fct_mrr_movements') }}
  GROUP BY 1
)
SELECT
  movement_month,
  new_mrr_usd,
  reactivation_mrr_usd,
  churn_mrr_usd,
  net_mrr_change_usd,
  SUM(net_mrr_change_usd) OVER (
    ORDER BY movement_month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS ending_mrr_usd
FROM monthly_movements
ORDER BY 1
