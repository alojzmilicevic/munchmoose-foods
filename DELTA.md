# The delta filter

Between full reloads, a nightly job keeps MunchMoose's copy fresh from Open Food Facts' daily delta files (https://static.openfoodfacts.org/data/delta/, `index.txt` lists the last 14 days; each file is one product JSON per line, gzipped). The job applies every file newer than the last one it applied, oldest first.

Per product line, the filter is the same as the extract's:

1. **Sweden only.** The product's `countries_tags` must contain `en:sweden`. Lines without that string are skipped unparsed.
2. **A barcode.** `code` must be a barcode (8 to 14 digits). Otherwise the product is skipped.
3. **A name.** `product_name_sv`, else `product_name`, else `product_name_en`, must be non-empty.
4. **Energy.** `energy-kcal` per 100 g or ml must be present: from `nutriments.energy-kcal_100g`, else from `nutrition.aggregated_set` when its `per` is `100g` or `100ml`.

What is kept per product is what the extract keeps (see README.md): name, first brand, the eight nutrients per 100, serving size when its unit matches, Nutri-Score grade, `last_modified_t`, `unique_scans_n`.

How it is written into the copy:

- **Upsert only.** A delta never deletes a product. Products that disappear from Open Food Facts are only marked as vanished by the next full reload.
- **Newer wins.** A product is overwritten only when its `last_modified_t` is newer than the copy's.
- **Never over our own data.** A product that a MunchMoose user scanned or added, or that a MunchMoose admin edited or verified, is left alone by deltas and reloads. Only rows the copy itself wrote are updated.

If the job has not run for longer than Open Food Facts keeps deltas, the changes in between are missed until the next full reload with `extract.sql`.
