{{ config(materialized='table') }}

SELECT
  customer_id,
  DATE_TRUNC('month', event_at) AS activity_month,
  COUNT(*) AS product_events
FROM {{ ref('stg_product_events') }}
GROUP BY 1, 2
