{{ config(materialized='view') }}
-- depends_on: {{ ref('subscription_events') }}

SELECT
  event_id,
  subscription_id,
  customer_id,
  event_type,
  CAST(event_at AS TIMESTAMP) AS event_at,
  plan_id,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('raw', 'subscription_events') }}
