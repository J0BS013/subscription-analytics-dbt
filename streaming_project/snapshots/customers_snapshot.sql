{% snapshot customers_snapshot %}

{{
  config(
    unique_key='customer_id',
    strategy='check',
    check_cols=['country', 'acquisition_channel'],
    invalidate_hard_deletes=True
  )
}}

SELECT
  customer_id,
  country,
  acquisition_channel,
  loaded_at
FROM {{ ref('stg_customers') }}

{% endsnapshot %}
