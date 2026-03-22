-- =============================================================================
-- Analytical Queries — part3-datawarehouse/dw_queries.sql
-- Runs against the star schema defined in star_schema.sql
-- Tables: fact_sales, dim_date, dim_store, dim_product
-- =============================================================================


-- Q1: Total sales revenue by product category for each month
-- Joins fact_sales → dim_product (for category) and dim_date (for month/year).
-- Groups by year + month + category to produce a monthly category breakdown.
-- ORDER BY year, month puts the results in chronological order.
SELECT
    d.year,
    d.month,
    d.month_name,
    p.category,
    SUM(f.total_revenue)  AS total_revenue,
    SUM(f.units_sold)     AS total_units_sold
FROM fact_sales    f
JOIN dim_date      d ON d.date_key    = f.date_key
JOIN dim_product   p ON p.product_key = f.product_key
GROUP BY
    d.year,
    d.month,
    d.month_name,
    p.category
ORDER BY
    d.year  ASC,
    d.month ASC,
    p.category ASC;


-- Q2: Top 2 performing stores by total revenue
-- Joins fact_sales → dim_store and aggregates total revenue per store.
-- LIMIT 2 returns only the top 2 after descending sort.
SELECT
    s.store_key,
    s.store_name,
    s.city,
    s.region,
    SUM(f.total_revenue)  AS total_revenue,
    SUM(f.units_sold)     AS total_units_sold,
    COUNT(f.transaction_id) AS total_transactions
FROM fact_sales  f
JOIN dim_store   s ON s.store_key = f.store_key
GROUP BY
    s.store_key,
    s.store_name,
    s.city,
    s.region
ORDER BY total_revenue DESC
LIMIT 2;


-- Q3: Month-over-month sales trend across all stores
-- Uses a window function (LAG) to compare each month's revenue with the
-- previous month's revenue, computing both the absolute change and the
-- percentage change. This reveals whether the business is growing or contracting.
-- The inner subquery gets monthly totals; the outer applies LAG.
SELECT
    year,
    month,
    month_name,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY year, month)  AS prev_month_revenue,
    ROUND(
        monthly_revenue
        - LAG(monthly_revenue) OVER (ORDER BY year, month),
        2
    )  AS revenue_change,
    ROUND(
        (
            (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year, month))
            / NULLIF(LAG(monthly_revenue) OVER (ORDER BY year, month), 0)
        ) * 100,
        2
    )  AS pct_change
FROM (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(f.total_revenue) AS monthly_revenue
    FROM fact_sales  f
    JOIN dim_date    d ON d.date_key = f.date_key
    GROUP BY
        d.year,
        d.month,
        d.month_name
) monthly_totals
ORDER BY year ASC, month ASC;
