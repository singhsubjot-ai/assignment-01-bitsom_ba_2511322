-- =============================================================================
-- Schema Design: orders_flat.csv → Third Normal Form (3NF)
-- =============================================================================
-- Normalization rationale:
--   The flat file violates 1NF/2NF/3NF because every non-key attribute
--   (customer name, product price, rep email, office address, etc.) repeats
--   on every order row.  We decompose into four tables so that each fact
--   is stored exactly once, eliminating the insert / update / delete anomalies
--   documented in normalization.md.
--
--   Tables:
--     1. sales_reps   – one row per sales representative
--     2. customers    – one row per customer
--     3. products     – one row per product
--     4. orders       – one row per order, FK → customers, products, sales_reps
-- =============================================================================


-- =============================================================================
-- 1. SALES_REPS
--    Primary key  : sales_rep_id  (e.g. SR01)
--    Eliminates   : repeating rep name / email / office_address in every order.
--    3NF check    : sales_rep_name, sales_rep_email, office_address all depend
--                   solely on sales_rep_id (no transitive dependency remains).
-- =============================================================================
CREATE TABLE IF NOT EXISTS sales_reps (
    sales_rep_id    VARCHAR(10)  NOT NULL,
    sales_rep_name  VARCHAR(100) NOT NULL,
    sales_rep_email VARCHAR(150) NOT NULL,
    office_address  VARCHAR(255) NOT NULL,
    CONSTRAINT pk_sales_reps PRIMARY KEY (sales_rep_id)
);

INSERT INTO sales_reps (sales_rep_id, sales_rep_name, sales_rep_email, office_address) VALUES
    ('SR01', 'Deepak Joshi', 'deepak@corp.com', 'Mumbai HQ, Nariman Point, Mumbai - 400021'),
    ('SR02', 'Anita Desai',  'anita@corp.com',  'Delhi Office, Connaught Place, New Delhi - 110001'),
    ('SR03', 'Ravi Kumar',   'ravi@corp.com',   'South Zone, MG Road, Bangalore - 560001');


-- =============================================================================
-- 2. CUSTOMERS
--    Primary key  : customer_id  (e.g. C001)
--    Eliminates   : repeating customer name / email / city in every order.
--    3NF check    : customer_name, customer_email, customer_city depend only on
--                   customer_id.
-- =============================================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id    VARCHAR(10)  NOT NULL,
    customer_name  VARCHAR(100) NOT NULL,
    customer_email VARCHAR(150) NOT NULL,
    customer_city  VARCHAR(100) NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
);

INSERT INTO customers (customer_id, customer_name, customer_email, customer_city) VALUES
    ('C001', 'Rohan Mehta',  'rohan@gmail.com',  'Mumbai'),
    ('C002', 'Priya Sharma', 'priya@gmail.com',  'Delhi'),
    ('C003', 'Amit Verma',   'amit@gmail.com',   'Bangalore'),
    ('C004', 'Sneha Iyer',   'sneha@gmail.com',  'Chennai'),
    ('C005', 'Vikram Singh', 'vikram@gmail.com', 'Mumbai'),
    ('C006', 'Neha Gupta',   'neha@gmail.com',   'Delhi'),
    ('C007', 'Arjun Nair',   'arjun@gmail.com',  'Bangalore'),
    ('C008', 'Kavya Rao',    'kavya@gmail.com',  'Hyderabad');


-- =============================================================================
-- 3. PRODUCTS
--    Primary key  : product_id  (e.g. P001)
--    Eliminates   : repeating product name / category / unit_price per order.
--    3NF check    : product_name, category, unit_price depend only on product_id.
--                   category does NOT transitively determine unit_price because
--                   different products in the same category have different prices
--                   (e.g. Mouse ₹800 vs Laptop ₹55,000 — both Electronics).
-- =============================================================================
CREATE TABLE IF NOT EXISTS products (
    product_id   VARCHAR(10)    NOT NULL,
    product_name VARCHAR(100)   NOT NULL,
    category     VARCHAR(50)    NOT NULL,
    unit_price   DECIMAL(10, 2) NOT NULL,
    CONSTRAINT pk_products PRIMARY KEY (product_id)
);

INSERT INTO products (product_id, product_name, category, unit_price) VALUES
    ('P001', 'Laptop',        'Electronics', 55000.00),
    ('P002', 'Mouse',         'Electronics',   800.00),
    ('P003', 'Desk Chair',    'Furniture',    8500.00),
    ('P004', 'Notebook',      'Stationery',    120.00),
    ('P005', 'Headphones',    'Electronics',  3200.00),
    ('P006', 'Standing Desk', 'Furniture',   22000.00),
    ('P007', 'Pen Set',       'Stationery',    250.00),
    ('P008', 'Webcam',        'Electronics',  2100.00);


-- =============================================================================
-- 4. ORDERS
--    Primary key  : order_id  (e.g. ORD1000)
--    Foreign keys : customer_id  → customers(customer_id)
--                   product_id   → products(product_id)
--                   sales_rep_id → sales_reps(sales_rep_id)
--    3NF check    : quantity and order_date depend only on order_id.
--                   Total value is a derived attribute (unit_price × quantity)
--                   and is therefore NOT stored — it is computed at query time
--                   via JOIN to products, avoiding redundancy.
--    Anomaly fix  :
--      Insert  → Products / Customers / SalesReps can be inserted independently.
--      Update  → office_address is stored once in sales_reps; one UPDATE fixes all.
--      Delete  → Deleting an order never removes the product / customer / rep record.
-- =============================================================================
CREATE TABLE IF NOT EXISTS orders (
    order_id      VARCHAR(10)  NOT NULL,
    customer_id   VARCHAR(10)  NOT NULL,
    product_id    VARCHAR(10)  NOT NULL,
    sales_rep_id  VARCHAR(10)  NOT NULL,
    quantity      INT          NOT NULL CHECK (quantity > 0),
    order_date    DATE         NOT NULL,
    CONSTRAINT pk_orders      PRIMARY KEY (order_id),
    CONSTRAINT fk_ord_cust    FOREIGN KEY (customer_id)  REFERENCES customers(customer_id),
    CONSTRAINT fk_ord_prod    FOREIGN KEY (product_id)   REFERENCES products(product_id),
    CONSTRAINT fk_ord_srep    FOREIGN KEY (sales_rep_id) REFERENCES sales_reps(sales_rep_id)
);

-- Inserting a representative sample of 10 orders (covering all tables)
INSERT INTO orders (order_id, customer_id, product_id, sales_rep_id, quantity, order_date) VALUES
    ('ORD1000', 'C002', 'P001', 'SR03', 2, '2023-05-21'),
    ('ORD1001', 'C004', 'P002', 'SR03', 5, '2023-02-22'),
    ('ORD1002', 'C002', 'P005', 'SR02', 1, '2023-01-17'),
    ('ORD1003', 'C002', 'P002', 'SR01', 5, '2023-09-16'),
    ('ORD1004', 'C001', 'P005', 'SR01', 5, '2023-11-29'),
    ('ORD1005', 'C007', 'P002', 'SR02', 3, '2023-10-29'),
    ('ORD1006', 'C001', 'P007', 'SR01', 4, '2023-12-24'),
    ('ORD1007', 'C006', 'P003', 'SR01', 3, '2023-04-21'),
    ('ORD1008', 'C002', 'P001', 'SR02', 3, '2023-02-19'),
    ('ORD1009', 'C006', 'P005', 'SR02', 4, '2023-01-23'),
    ('ORD1010', 'C002', 'P004', 'SR01', 3, '2023-10-10'),
    ('ORD1011', 'C006', 'P005', 'SR01', 1, '2023-12-27'),
    ('ORD1012', 'C001', 'P006', 'SR01', 1, '2023-05-29'),
    ('ORD1013', 'C004', 'P007', 'SR01', 3, '2023-07-14'),
    ('ORD1014', 'C008', 'P006', 'SR02', 3, '2023-03-25'),
    ('ORD1185', 'C003', 'P008', 'SR03', 1, '2023-06-15');
-- (All 187 orders from the CSV are representable; the above 16 rows fulfil the
--  "≥5 rows per table" requirement.  The products, customers, and sales_reps
--  tables already carry their full datasets above.)
