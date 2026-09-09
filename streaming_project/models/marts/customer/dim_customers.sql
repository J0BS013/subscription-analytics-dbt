{{ config(materialized='table') }}

SELECT
  customer_id,
  email,
  country,
  acquisition_channel,
  created_at
FROM {{ ref('stg_customers') }}
