-- =============================================================================
-- DuckDB Cross-Format Queries — part5-datalake/duckdb_queries.sql
-- Reads DIRECTLY from raw files — no pre-loaded tables.
--
-- File paths assume DuckDB is run from the project root:
--   c:\Users\rkgam\OneDrive\Desktop\Projects\Rishi Assignment\
--
-- File formats:
--   datasets/customers.csv     → CSV  (customer_id, name, city, signup_date, email)
--   datasets/orders.json       → JSON (order_id, customer_id, order_date, status,
--                                      total_amount, num_items)
--   datasets/products.parquet  → Parquet (product details — columns inspected below)
--
-- NOTE: DuckDB reads JSON arrays directly with read_json_auto(). The orders file
--       is a JSON array of objects, so no extra unnesting is needed.
-- =============================================================================


-- Q1: List all customers along with the total number of orders they have placed
-- Reads customers.csv and orders.json directly; LEFT JOIN preserves customers with 0 orders.
SELECT
    c.customer_id,
    c.name               AS customer_name,
    c.city,
    COUNT(o.order_id)    AS total_orders
FROM read_csv_auto('datasets/customers.csv') AS c
LEFT JOIN read_json_auto('datasets/orders.json') AS o
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.name,
    c.city
ORDER BY total_orders DESC, c.name ASC;


-- Q2: Find the top 3 customers by total order value
-- total_amount is stored in orders.json; we sum it per customer and join
-- customer names from customers.csv. LIMIT 3 after descending sort.
SELECT
    c.customer_id,
    c.name                   AS customer_name,
    c.city,
    SUM(o.total_amount)      AS total_order_value,
    COUNT(o.order_id)        AS total_orders
FROM read_csv_auto('datasets/customers.csv') AS c
JOIN read_json_auto('datasets/orders.json') AS o
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.name,
    c.city
ORDER BY total_order_value DESC
LIMIT 3;


-- Q3: List all products purchased by customers from Bangalore
-- Join path: customers (WHERE city='Bangalore') → orders (customer_id)
--            → products line-items (order_id).
-- products.parquet columns: line_item_id, order_id, product_id, product_name,
--                           category, quantity, unit_price, total_price
SELECT DISTINCT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price
FROM read_csv_auto('datasets/customers.csv')   AS c
JOIN read_json_auto('datasets/orders.json')    AS o  ON o.customer_id = c.customer_id
JOIN read_parquet('datasets/products.parquet') AS p  ON p.order_id    = o.order_id
WHERE c.city = 'Bangalore'
ORDER BY p.category ASC, p.product_name ASC;


-- Q4: Join all three files to show: customer name, order date, product name, quantity
-- Full three-way join using both concrete shared keys:
--   customers.customer_id = orders.customer_id
--   orders.order_id       = products.order_id  (line-items join)
SELECT
    c.name                   AS customer_name,
    c.city                   AS customer_city,
    o.order_date,
    o.status                 AS order_status,
    p.product_name,
    p.category,
    p.quantity,
    p.unit_price,
    p.total_price
FROM read_csv_auto('datasets/customers.csv')   AS c
JOIN read_json_auto('datasets/orders.json')    AS o  ON o.customer_id = c.customer_id
JOIN read_parquet('datasets/products.parquet') AS p  ON p.order_id    = o.order_id
ORDER BY
    o.order_date   DESC,
    c.name         ASC,
    p.product_name ASC;
