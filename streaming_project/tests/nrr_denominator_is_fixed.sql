SELECT movement_month
FROM {{ ref('mart_nrr_monthly') }}
GROUP BY 1
HAVING MIN(initial_cohort_mrr_usd) <> MAX(initial_cohort_mrr_usd)
