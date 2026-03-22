# ETL Notes — retail_transactions.csv

## ETL Decisions

### Decision 1 — Standardising Inconsistent Date Formats

**Problem:**  
The `date` column in `retail_transactions.csv` contains three different formats across rows:
- `DD/MM/YYYY` (e.g., `29/08/2023` on TXN5000)
- `DD-MM-YYYY` (e.g., `12-12-2023` on TXN5001)
- `YYYY-MM-DD` ISO format (e.g., `2023-02-05` on TXN5002)

A data warehouse must store dates in a single, consistent format so that `dim_date` surrogate keys (formatted as YYYYMMDD integers) can be reliably computed, and so that range queries on `dim_date.full_date` behave correctly. Mixing formats would cause incorrect date parsing — for example, `04/06/2023` could be misread as April 6 instead of June 4 if the format is assumed wrongly.

**Resolution:**  
During ETL, all date strings were parsed using a multi-format parser that first detects the separator character (`/` or `-`) and the position of the 4-digit year component (first vs. last). All dates were then converted to ISO 8601 (`YYYY-MM-DD`) before being transformed into the `dim_date.date_key` integer (YYYYMMDD). The final `INSERT` statements in `star_schema.sql` use only ISO-formatted dates, which are loaded into `dim_date.full_date` as SQL `DATE` values.

---

### Decision 2 — Resolving NULL store_city Values

**Problem:**  
Several rows in the raw CSV have a blank (NULL) value in the `store_city` column — for example, TXN5033 (`Mumbai Central`, city blank), TXN5044 (`Chennai Anna`, city blank), TXN5082 (`Delhi South`, city blank), and TXN5094 (`Delhi South`, city blank). In a data warehouse, a NULL city would break geographic roll-up reports (revenue by city, revenue by region) because those rows would be omitted from GROUP BY aggregations or grouped together under a misleading "Unknown" bucket.

**Resolution:**  
The `store_name` column is always populated and maps deterministically to a city (e.g., `"Chennai Anna"` always maps to `"Chennai"`, `"Delhi South"` always maps to `"Delhi"`). A lookup table was derived from the non-null rows in the same file and used to back-fill the missing city values. This lookup is encoded directly in `dim_store`, which stores the authoritative `city` for each `store_name`. Every fact row references `dim_store.store_key`, so the city is always resolved via the dimension table regardless of what the raw CSV contained — NULL city values are no longer an issue at query time.

---

### Decision 3 — Normalising Category Casing

**Problem:**  
The `category` column uses inconsistent casing throughout the raw file:
- `"electronics"` (all lowercase) — appears in TXN5000, TXN5006, TXN5009, and many other rows
- `"Electronics"` (title case) — used in most other electronic product rows
- `"Groceries"` and `"Grocery"` — two different spellings for the same category

This inconsistency means a simple `GROUP BY category` would return four separate groups instead of two, producing completely incorrect subtotals for the Electronics and Grocery categories in any BI report.

**Resolution:**  
All category values were standardised to title-case canonical names during the ETL transform step:
- `"electronics"` → `"Electronics"`
- `"Grocery"` and `"Groceries"` → `"Grocery"` (singular, to match the product naming)
- `"Clothing"` — already consistent, unchanged

This canonical value is stored in `dim_product.category`. Because the fact table references `dim_product.product_key` rather than storing the category string directly, all queries automatically use the cleaned, standardised category regardless of what the original raw file contained.
