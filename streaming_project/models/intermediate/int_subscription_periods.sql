{{ config(materialized='table') }}

WITH subscription_events AS (
  SELECT * FROM {{ ref('stg_subscription_events') }}
),
first_activation AS (
  SELECT
    subscription_id,
    MIN(event_at) AS activated_at
  FROM subscription_events
  WHERE event_type = 'activated'
  GROUP BY 1
),
first_cancellation AS (
  SELECT
    subscription_id,
    MIN(event_at) AS cancelled_at
  FROM subscription_events
  WHERE event_type = 'cancelled'
  GROUP BY 1
),
subscription_plan AS (
  SELECT
    subscription_id,
    customer_id,
    plan_id,
    ROW_NUMBER() OVER (PARTITION BY subscription_id ORDER BY event_at) AS plan_sequence
  FROM subscription_events
  WHERE event_type IN ('activated', 'trial_started')
)
SELECT
  activation.subscription_id,
  plan.customer_id,
  plan.plan_id,
  CAST(activation.activated_at AS DATE) AS subscription_start_date,
  CAST(cancellation.cancelled_at AS DATE) AS subscription_cancelled_date,
  plans.monthly_price_usd AS monthly_mrr_usd
FROM first_activation AS activation
INNER JOIN subscription_plan AS plan
  ON activation.subscription_id = plan.subscription_id
  AND plan.plan_sequence = 1
INNER JOIN {{ ref('stg_plans') }} AS plans
  ON plan.plan_id = plans.plan_id
LEFT JOIN first_cancellation AS cancellation
  ON activation.subscription_id = cancellation.subscription_id
