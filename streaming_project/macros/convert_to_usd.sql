{% macro convert_to_usd(amount, currency, fx_rate) %}
  CASE
    WHEN {{ currency }} = 'USD' THEN {{ amount }}
    WHEN {{ fx_rate }} IS NOT NULL THEN {{ amount }} * {{ fx_rate }}
    ELSE NULL
  END
{% endmacro %}
