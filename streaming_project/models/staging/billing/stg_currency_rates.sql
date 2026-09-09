{{ config(materialized='view') }}
-- depends_on: {{ ref('currency_rates') }}

SELECT
  CAST(rate_date AS DATE) AS rate_date,
  UPPER(base_currency) AS base_currency,
  UPPER(quote_currency) AS quote_currency,
  CAST(rate AS DECIMAL(18, 6)) AS rate,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('raw', 'currency_rates') }}
