{% macro safe_divide(numerator, denominator, default_value='NULL') %}
  CASE
    WHEN {{ denominator }} IS NULL OR {{ denominator }} = 0 THEN {{ default_value }}
    ELSE {{ numerator }} / {{ denominator }}
  END
{% endmacro %}
