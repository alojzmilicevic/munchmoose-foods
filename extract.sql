-- munchmoose-foods: every Open Food Facts product sold in Sweden, from their Parquet dump, as one JSON array.
-- Seeds and fully reloads the MunchMoose Products copy (see README.md and DELTA.md).
-- Run with DuckDB from this folder, the dump in data/dump/food.parquet: duckdb < extract.sql
CREATE TEMP TABLE se AS
SELECT
  code,
  list_filter(product_name, lambda x: x.lang = 'sv')[1].text AS product_name_sv,
  coalesce(list_filter(product_name, lambda x: x.lang = 'main')[1].text, product_name[1].text) AS product_name,
  brands, quantity, serving_quantity, product_quantity_unit, nutriscore_grade, last_modified_t,
  list_filter(nutriments, lambda n: n.name = 'energy-kcal')[1]."100g" AS kcal,
  list_filter(nutriments, lambda n: n.name = 'proteins')[1]."100g" AS protein,
  list_filter(nutriments, lambda n: n.name = 'carbohydrates')[1]."100g" AS carbs,
  list_filter(nutriments, lambda n: n.name = 'fat')[1]."100g" AS fat,
  list_filter(nutriments, lambda n: n.name = 'sugars')[1]."100g" AS sugar,
  list_filter(nutriments, lambda n: n.name = 'saturated-fat')[1]."100g" AS saturated_fat,
  list_filter(nutriments, lambda n: n.name = 'fiber')[1]."100g" AS fiber,
  list_filter(nutriments, lambda n: n.name = 'salt')[1]."100g" AS salt,
  unique_scans_n, popularity_key, completeness
FROM read_parquet('data/dump/food.parquet')
WHERE list_contains(countries_tags, 'en:sweden');

COPY (SELECT
  (SELECT count(*) FROM se) AS rows_in,
  (SELECT count(*) FROM se WHERE coalesce(trim(product_name_sv), trim(product_name), '') = '') AS no_name,
  (SELECT count(*) FROM se WHERE kcal IS NULL) AS no_kcal,
  (SELECT count(*) FROM se WHERE coalesce(trim(product_name_sv), trim(product_name), '') <> '' AND kcal IS NOT NULL) AS kept,
  (SELECT count(*) - count(DISTINCT lower(coalesce(product_name_sv, product_name)) || '|' || lower(coalesce(brands, '')))
     FROM se WHERE coalesce(trim(product_name_sv), trim(product_name), '') <> '' AND kcal IS NOT NULL) AS duplicate_name_brand
) TO 'data/products-se-counts.json' (FORMAT json);

COPY (SELECT * FROM se WHERE coalesce(trim(product_name_sv), trim(product_name), '') <> '' AND kcal IS NOT NULL ORDER BY code)
TO 'data/products-se.json' (FORMAT json, ARRAY true);
