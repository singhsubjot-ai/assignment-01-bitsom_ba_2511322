-- =============================================================================
-- Star Schema Design — retail_transactions.csv
-- Part 3: Data Warehouse
-- =============================================================================
-- Raw data issues handled before loading (see etl_notes.md):
--   1. Inconsistent date formats (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD) → YYYY-MM-DD
--   2. NULL / missing store_city values → resolved from store_name lookup
--   3. Inconsistent category casing (electronics / Electronics) → title-cased value
-- =============================================================================


-- =============================================================================
-- DIMENSION: dim_date
-- Purpose: Enables time-based slicing — by day, month, quarter, year.
--          Storing derived attributes avoids expensive DATE functions
--          in every BI query.
-- =============================================================================
CREATE TABLE IF NOT EXISTS dim_date (
    date_key    INT          NOT NULL,   -- surrogate key, format: YYYYMMDD
    full_date   DATE         NOT NULL,
    day         SMALLINT     NOT NULL,
    month       SMALLINT     NOT NULL,
    month_name  VARCHAR(10)  NOT NULL,
    quarter     SMALLINT     NOT NULL,
    year        SMALLINT     NOT NULL,
    is_weekend  BOOLEAN      NOT NULL,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key)
);

INSERT INTO dim_date (date_key, full_date, day, month, month_name, quarter, year, is_weekend) VALUES
    (20230101, '2023-01-01', 1,  1,  'January',   1, 2023, TRUE),
    (20230115, '2023-01-15', 15, 1,  'January',   1, 2023, FALSE),
    (20230205, '2023-02-05', 5,  2,  'February',  1, 2023, FALSE),
    (20230307, '2023-03-07', 7,  3,  'March',     1, 2023, FALSE),
    (20230514, '2023-05-14', 14, 5,  'May',       2, 2023, FALSE),
    (20230521, '2023-05-21', 21, 5,  'May',       2, 2023, FALSE),
    (20230604, '2023-06-04', 4,  6,  'June',      2, 2023, FALSE),
    (20230722, '2023-07-22', 22, 7,  'July',      3, 2023, FALSE),
    (20230809, '2023-08-09', 9,  8,  'August',    3, 2023, FALSE),
    (20230829, '2023-08-29', 29, 8,  'August',    3, 2023, FALSE),
    (20231026, '2023-10-26', 26, 10, 'October',   4, 2023, FALSE),
    (20231118, '2023-11-18', 18, 11, 'November',  4, 2023, FALSE),
    (20231208, '2023-12-08', 8,  12, 'December',  4, 2023, FALSE);


-- =============================================================================
-- DIMENSION: dim_store
-- Purpose: Centralises store metadata — city, region — for geographic analysis.
--          Eliminates repeating store name + city on every fact row.
-- =============================================================================
CREATE TABLE IF NOT EXISTS dim_store (
    store_key   INT          NOT NULL,   -- surrogate key
    store_name  VARCHAR(100) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    region      VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_dim_store PRIMARY KEY (store_key)
);

INSERT INTO dim_store (store_key, store_name, city, region) VALUES
    (1, 'Chennai Anna',    'Chennai',   'South'),
    (2, 'Delhi South',     'Delhi',     'North'),
    (3, 'Bangalore MG',    'Bangalore', 'South'),
    (4, 'Pune FC Road',    'Pune',      'West'),
    (5, 'Mumbai Central',  'Mumbai',    'West');


-- =============================================================================
-- DIMENSION: dim_product
-- Purpose: Stores product name and standardised category.
--          Casing was normalised (electronics → Electronics) during ETL.
-- =============================================================================
CREATE TABLE IF NOT EXISTS dim_product (
    product_key   INT          NOT NULL,   -- surrogate key
    product_name  VARCHAR(100) NOT NULL,
    category      VARCHAR(50)  NOT NULL,   -- standardised: Electronics / Clothing / Grocery
    unit_price    DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_dim_product PRIMARY KEY (product_key)
);

INSERT INTO dim_product (product_key, product_name, category, unit_price) VALUES
    (1,  'Speaker',       'Electronics', 49262.78),
    (2,  'Tablet',        'Electronics', 23226.12),
    (3,  'Phone',         'Electronics', 48703.39),
    (4,  'Smartwatch',    'Electronics', 58851.01),
    (5,  'Laptop',        'Electronics', 42343.15),
    (6,  'Headphones',    'Electronics', 39854.96),
    (7,  'Jeans',         'Clothing',    2317.47),
    (8,  'Jacket',        'Clothing',    30187.24),
    (9,  'Saree',         'Clothing',    35451.81),
    (10, 'T-Shirt',       'Clothing',    29770.19),
    (11, 'Atta 10kg',     'Grocery',     52464.00),
    (12, 'Biscuits',      'Grocery',     27469.99),
    (13, 'Rice 5kg',      'Grocery',     52195.05),
    (14, 'Milk 1L',       'Grocery',     43374.39),
    (15, 'Pulses 1kg',    'Grocery',     31604.47),
    (16, 'Oil 1L',        'Grocery',     26474.34);


-- =============================================================================
-- FACT TABLE: fact_sales
-- Grain: one row per transaction (transaction_id)
-- Measures: units_sold, unit_price (snapshot), total_revenue
--           total_revenue = units_sold × unit_price is stored to avoid
--           recomputing it in every BI query.
-- Foreign keys link to all three dimension tables.
-- =============================================================================
CREATE TABLE IF NOT EXISTS fact_sales (
    transaction_id  VARCHAR(10)    NOT NULL,
    date_key        INT            NOT NULL,
    store_key       INT            NOT NULL,
    product_key     INT            NOT NULL,
    customer_id     VARCHAR(10)    NOT NULL,
    units_sold      INT            NOT NULL CHECK (units_sold > 0),
    unit_price      DECIMAL(12, 2) NOT NULL,
    total_revenue   DECIMAL(15, 2) NOT NULL,
    CONSTRAINT pk_fact_sales     PRIMARY KEY (transaction_id),
    CONSTRAINT fk_fact_date      FOREIGN KEY (date_key)    REFERENCES dim_date(date_key),
    CONSTRAINT fk_fact_store     FOREIGN KEY (store_key)   REFERENCES dim_store(store_key),
    CONSTRAINT fk_fact_product   FOREIGN KEY (product_key) REFERENCES dim_product(product_key)
);

-- 15 cleaned fact rows drawn from retail_transactions.csv
-- ETL normalisation applied: date → YYYY-MM-DD, category → title-case,
--                            NULL cities resolved from store lookup
INSERT INTO fact_sales
    (transaction_id, date_key,  store_key, product_key, customer_id, units_sold, unit_price,  total_revenue)
VALUES
    ('TXN5000', 20230829, 1, 1,  'CUST045',  3,  49262.78,  147788.34),  -- Speaker,    Chennai Anna
    ('TXN5001', 20231208, 1, 2,  'CUST021', 11,  23226.12,  255487.32),  -- Tablet,     Chennai Anna
    ('TXN5002', 20230205, 1, 3,  'CUST019', 20,  48703.39,  974067.80),  -- Phone,      Chennai Anna
    ('TXN5004', 20230115, 1, 4,  'CUST004', 10,  58851.01,  588510.10),  -- Smartwatch, Chennai Anna
    ('TXN5005', 20230809, 3, 11, 'CUST027', 12,  52464.00,  629568.00),  -- Atta 10kg,  Bangalore MG
    ('TXN5007', 20231026, 4, 7,  'CUST041', 16,   2317.47,   37079.52),  -- Jeans,      Pune FC Road
    ('TXN5008', 20231208, 3, 12, 'CUST030',  9,  27469.99,  247229.91),  -- Biscuits,   Bangalore MG
    ('TXN5012', 20230521, 3, 5,  'CUST044', 13,  42343.15,  550461.95),  -- Laptop,     Bangalore MG
    ('TXN5014', 20231118, 2, 8,  'CUST042',  5,  30187.24,  150936.20),  -- Jacket,     Delhi South
    ('TXN5018', 20230205, 3, 6,  'CUST015', 15,  39854.96,  597824.40),  -- Headphones, Bangalore MG
    ('TXN5023', 20230115, 1, 6,  'CUST032',  5,  39854.96,  199274.80),  -- Headphones, Chennai Anna
    ('TXN5024', 20231026, 5, 6,  'CUST024',  8,  39854.96,  318839.68),  -- Headphones, Mumbai Central
    ('TXN5029', 20230101, 5, 10, 'CUST016', 20,  29770.19,  595403.80),  -- T-Shirt,    Mumbai Central
    ('TXN5034', 20230307, 5, 1,  'CUST031', 14,  49262.78,  689678.92),  -- Speaker,    Mumbai Central
    ('TXN5036', 20230604, 4, 3,  'CUST002', 17,  48703.39,  827957.63);  -- Phone,      Pune FC Road
