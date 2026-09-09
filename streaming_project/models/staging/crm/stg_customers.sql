{{ config(materialized='view') }}
-- depends_on: {{ ref('customers') }}

SELECT
  customer_id,
  LOWER(email) AS email,
  UPPER(country) AS country,
  acquisition_channel,
  CAST(created_at AS DATE) AS created_at,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('raw', 'customers') }}
