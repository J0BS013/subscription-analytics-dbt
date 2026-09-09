SELECT cohort_month
FROM {{ ref('mart_retention_cohorts') }}
GROUP BY 1
HAVING MIN(cohort_size) <> MAX(cohort_size)
