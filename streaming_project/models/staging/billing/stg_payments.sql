{{ config(materialized='view') }}
-- depends_on: {{ ref('payments') }}

SELECT
  payment_id,
  invoice_id,
  CAST(payment_date AS DATE) AS payment_date,
  CAST(amount AS DECIMAL(18, 2)) AS amount,
  UPPER(currency) AS currency,
  payment_status,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('raw', 'payments') }}
