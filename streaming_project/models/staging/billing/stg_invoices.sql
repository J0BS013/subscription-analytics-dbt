{{ config(materialized='view') }}
-- depends_on: {{ ref('invoices') }}

SELECT
  invoice_id,
  subscription_id,
  customer_id,
  CAST(invoice_date AS DATE) AS invoice_date,
  UPPER(currency) AS currency,
  CAST(total_amount AS DECIMAL(18, 2)) AS total_amount,
  status,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('raw', 'invoices') }}
