{{ config(materialized='view') }}
-- depends_on: {{ ref('product_events') }}

SELECT
  product_event_id,
  customer_id,
  event_name,
  CAST(event_at AS TIMESTAMP) AS event_at,
  platform,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('raw', 'product_events') }}
