{{ config(materialized='view') }}

SELECT
  CAST(user_id AS VARCHAR) AS customer_id,
  CAST(signup_date AS DATE) AS signup_date,
  CAST(cancel_date AS DATE) AS cancel_date,
  plan_type
FROM {{ source('raw', 'subscriptions') }}
