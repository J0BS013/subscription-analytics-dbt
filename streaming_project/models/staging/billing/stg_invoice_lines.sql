{{ config(materialized='view') }}
-- depends_on: {{ ref('invoice_lines') }}

SELECT
  invoice_line_id,
  invoice_id,
  plan_id,
  CAST(quantity AS INTEGER) AS quantity,
  CAST(amount AS DECIMAL(18, 2)) AS amount,
  CAST(loaded_at AS TIMESTAMP) AS loaded_at
FROM {{ source('raw', 'invoice_lines') }}
