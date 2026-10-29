# munchmoose-foods

## About

This project is provided in compliance with Section 4.6 b. of the [ODbL](https://opendatacommons.org/licenses/odbl/1-0/).

[MunchMoose](https://github.com/alojzmilicevic) is a food logging app for iOS and Android. Its packaged products come from [Open Food Facts](https://world.openfoodfacts.org/), made available under the [Open Database License](https://opendatacommons.org/licenses/odbl/1-0/) (ODbL). MunchMoose keeps its own copy of the products sold in Sweden (a Derivative Database in the ODbL's words) and does not publish that copy. Instead, this repository is the alteration file: it holds exactly what MunchMoose takes from Open Food Facts and how it changes it, so anyone with the same Open Food Facts data can rebuild the copy.

- `extract.sql`: the extract that seeds the copy, and fully reloads it a few times a year, from Open Food Facts' Parquet dump.
- `DELTA.md`: the filter MunchMoose applies to Open Food Facts' daily delta files to keep the copy fresh in between.

MunchMoose's generic foods (raw and plain foods with no barcode) come from [Livsmedelsverket](https://www.livsmedelsverket.se/)'s food database under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), adapted. That data is not covered here.

## What the extract does

From the dump, `extract.sql` takes every product whose `countries_tags` contains `en:sweden` and keeps, per product: the barcode (`code`), the Swedish name (`product_name`'s `sv` entry) and the main name, `brands`, `quantity`, `serving_quantity`, `product_quantity_unit`, `nutriscore_grade`, `last_modified_t`, `unique_scans_n`, `popularity_key`, `completeness`, and these nutrients per 100 g or ml: energy (kcal), protein, carbohydrates, fat, sugars, saturated fat, fibre, salt. Everything else in the dump is dropped.

Products with no name (neither Swedish nor main, after trimming) or no energy in kcal are left out. The output is one JSON array, `data/products-se.json`, ordered by barcode, plus `data/products-se-counts.json` with how many rows came in and were kept. With the dump of 2026-10-26: 28,152 products sold in Sweden, 25,367 kept.

When MunchMoose loads the file, it uses the Swedish name when there is one, else the main name; the first brand of `brands`; the nutrients rounded to three decimals (the dump stores them as 32-bit floats); a serving size only when its unit is the product's base unit; and a Nutri-Score only when it is a grade A–E. A barcode present twice keeps its newest `last_modified_t`. Products a later file no longer has are marked as vanished, never deleted.

## Running it

Needs [DuckDB](https://duckdb.org/) and Open Food Facts' Parquet dump:

1. Download `food.parquet` from https://huggingface.co/datasets/openfoodfacts/product-database (about 8 GB) into `data/dump/`.
2. Run `duckdb < extract.sql` from this folder. About 2 seconds.

## Licence

This repository (the SQL and these documents) is under the [MIT License](LICENSE). The Open Food Facts data it reads and produces stays under the ODbL; the database contents under the [Database Contents License](https://opendatacommons.org/licenses/dbcl/1-0/).
