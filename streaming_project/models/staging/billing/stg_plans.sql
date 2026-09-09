{{ config(materialized='view') }}
-- depends_on: {{ ref('plans') }}

SELECT
  plan_id,
  plan_name,
  product_name,
  CAST(monthly_price_usd AS DECIMAL(18, 2)) AS monthly_price_usd,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('raw', 'plans') }}
