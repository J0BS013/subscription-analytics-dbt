{{ config(materialized='table', contract={'enforced': true}) }}

SELECT
  movement_id,
  subscription_id,
  customer_id,
  CAST(movement_month AS DATE) AS movement_month,
  movement_type,
  CAST(mrr_delta_usd AS DECIMAL(18, 2)) AS mrr_delta_usd
FROM {{ ref('int_mrr_movements') }}
