{{ config(materialized='table') }}

WITH subscription_events AS (
  SELECT * FROM {{ ref('stg_subscription_events') }}
),
priced_events AS (
  SELECT
    events.event_id,
    events.subscription_id,
    events.customer_id,
    CAST(events.event_at AS DATE) AS movement_date,
    events.event_type,
    plans.monthly_price_usd
  FROM subscription_events AS events
  INNER JOIN {{ ref('stg_plans') }} AS plans
    ON events.plan_id = plans.plan_id
  WHERE events.event_type IN ('activated', 'cancelled')
),
ordered_events AS (
  SELECT
    *,
    LAG(event_type) OVER (
      PARTITION BY subscription_id
      ORDER BY movement_date, event_id
    ) AS previous_event_type
  FROM priced_events
)
SELECT
  event_id AS movement_id,
  subscription_id,
  customer_id,
  DATE_TRUNC('month', movement_date) AS movement_month,
  CASE
    WHEN event_type = 'cancelled' THEN 'churn'
    WHEN previous_event_type = 'cancelled' THEN 'reactivation'
    ELSE 'new'
  END AS movement_type,
  CASE WHEN event_type = 'cancelled' THEN -monthly_price_usd ELSE monthly_price_usd END AS mrr_delta_usd
FROM ordered_events
