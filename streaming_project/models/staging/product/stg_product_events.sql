{{ config(materialized='view') }}
-- depends_on: {{ ref('product_events') }}

WITH ranked_events AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY product_event_id ORDER BY loaded_at DESC) AS row_number
  FROM {{ source('raw', 'product_events') }}
)
SELECT
  product_event_id,
  customer_id,
  event_name,
  CAST(event_at AS TIMESTAMP) AS event_at,
  platform,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM ranked_events
WHERE row_number = 1
