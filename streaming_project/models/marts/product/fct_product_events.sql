{{
  config(
    materialized='incremental',
    unique_key='product_event_id',
    incremental_strategy='delete+insert'
  )
}}

SELECT
  product_event_id,
  customer_id,
  event_name,
  event_at,
  platform,
  loaded_at
FROM {{ ref('stg_product_events') }}
{% if is_incremental() %}
  WHERE event_at >= (
    SELECT COALESCE(MAX(event_at) - INTERVAL 7 DAY, CAST('1900-01-01' AS TIMESTAMP))
    FROM {{ this }}
  )
{% endif %}
