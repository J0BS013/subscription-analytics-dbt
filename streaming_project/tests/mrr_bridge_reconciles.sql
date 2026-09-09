WITH bridge AS (
  SELECT
    movement_month,
    ending_mrr_usd,
    net_mrr_change_usd,
    LAG(ending_mrr_usd, 1, 0) OVER (ORDER BY movement_month) AS prior_ending_mrr_usd
  FROM {{ ref('mart_mrr_monthly') }}
)
SELECT *
FROM bridge
WHERE ending_mrr_usd <> prior_ending_mrr_usd + net_mrr_change_usd
