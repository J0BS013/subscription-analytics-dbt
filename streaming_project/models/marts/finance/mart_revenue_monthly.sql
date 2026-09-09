{{ config(materialized='table') }}

WITH paid_invoices AS (
  SELECT *
  FROM {{ ref('stg_invoices') }}
  WHERE status = 'paid'
),
successful_payments AS (
  SELECT invoice_id
  FROM {{ ref('stg_payments') }}
  WHERE payment_status = 'succeeded'
),
converted_invoices AS (
  SELECT
    DATE_TRUNC('month', invoices.invoice_date) AS revenue_month,
    invoices.invoice_id,
    {{ convert_to_usd('invoices.total_amount', 'invoices.currency', 'rates.rate') }} AS revenue_usd
  FROM paid_invoices AS invoices
  INNER JOIN successful_payments AS payments
    ON invoices.invoice_id = payments.invoice_id
  LEFT JOIN {{ ref('stg_currency_rates') }} AS rates
    ON invoices.currency = rates.base_currency
    AND DATE_TRUNC('month', invoices.invoice_date) = rates.rate_date
    AND rates.quote_currency = 'USD'
)
SELECT
  revenue_month,
  COUNT(DISTINCT invoice_id) AS paid_invoices,
  CAST(SUM(revenue_usd) AS DECIMAL(18, 2)) AS revenue_usd
FROM converted_invoices
GROUP BY 1
ORDER BY 1
