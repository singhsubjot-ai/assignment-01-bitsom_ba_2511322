# Normalization Report — orders_flat.csv

## Anomaly Analysis

The flat file `orders_flat.csv` stores all data — customer details, product details, sales representative details, and order details — in a single table. This design introduces three classic types of data anomalies, detailed below.

---

### Insert Anomaly

**Definition:** An insert anomaly occurs when a new fact cannot be recorded in the database without the existence of another, unrelated fact.

**Example from the dataset:**

In `orders_flat.csv`, product information (`product_id`, `product_name`, `category`, `unit_price`) is stored only as part of an order row. Suppose a new product **P009 — Keyboard** (Electronics, ₹1,500) is added to the catalogue before any customer orders it. There is **no way to insert this product** into the flat table without fabricating a fake order row, because the table has no concept of a product independent of an order.

- **Affected columns:** `product_id`, `product_name`, `category`, `unit_price`
- **Affected scenario:** Any new product (e.g., P009) that exists in inventory but has zero orders yet  
- **Concrete illustration:** Every row in the CSV that mentions P001 (Laptop) has an accompanying `order_id`. Without an order, P001's price of ₹55,000 and its category "Electronics" simply cannot be stored.

The same anomaly applies to customers and sales representatives — you cannot record a new customer (e.g., C009) or a new sales rep (e.g., SR04) until they are associated with an actual order.

---

### Update Anomaly

**Definition:** An update anomaly occurs when updating a single real-world fact requires changes to multiple rows, and a partial update leaves the database in an inconsistent state.

**Example from the dataset:**

Sales representative SR01 (Deepak Joshi, deepak@corp.com) is associated with the office address `"Mumbai HQ, Nariman Point, Mumbai - 400021"`. However, in several rows the address is recorded as the abbreviated `"Mumbai HQ, Nariman Pt, Mumbai - 400021"` (note **"Nariman Pt"** vs. **"Nariman Point"**).

| Row (CSV line) | order_id | sales_rep_id | office_address stored |
|---|---|---|---|
| Line 39  | ORD1180 | SR01 | `"Mumbai HQ, Nariman Pt, Mumbai - 400021"` |
| Line 58  | ORD1173 | SR01 | `"Mumbai HQ, Nariman Pt, Mumbai - 400021"` |
| Line 91  | ORD1170 | SR01 | `"Mumbai HQ, Nariman Pt, Mumbai - 400021"` |
| Line 94  | ORD1183 | SR01 | `"Mumbai HQ, Nariman Pt, Mumbai - 400021"` |
| Line 11  | ORD1091 | SR01 | `"Mumbai HQ, Nariman Point, Mumbai - 400021"` ✓ |

SR01's true office address appears in the majority of rows as `"Mumbai HQ, Nariman Point, Mumbai - 400021"`, but at least **4 rows** contain the inconsistent abbreviated form. If SR01 were to move offices, every one of the dozens of rows referencing SR01 would need to be updated individually. Even a single missed row would leave the database inconsistent — a textbook update anomaly.

- **Affected columns:** `office_address` (linked to `sales_rep_id`)
- **Affected rows (CSV line numbers):** Lines 39, 58, 91, 94, 98, 100, 112, 124, 127, 131, 154, 156, 160, 172, 175, 176, 182 (all rows where SR01's address is abbreviated)

---

### Delete Anomaly

**Definition:** A delete anomaly occurs when deleting a row to remove one fact unintentionally destroys other, unrelated facts.

**Example from the dataset:**

Product **P008 — Webcam** (Electronics, ₹2,100) appears in **exactly one row** in the entire CSV:

| Row (CSV line) | order_id  | customer_id | product_id | product_name | category    | unit_price |
|---|---|---|---|---|---|---|
| Line 13        | ORD1185   | C003        | P008       | Webcam       | Electronics | 2100       |

If order **ORD1185** is deleted (e.g., because Amit Verma, C003, cancelled it), **all knowledge of product P008 (Webcam) — its name, category, and unit price of ₹2,100 — is permanently lost** from the database. The flat table provides no way to retain product information independently of the orders that reference it.

- **Affected columns:** `product_id`, `product_name`, `category`, `unit_price`
- **Affected row:** Line 13, `order_id = ORD1185`

---

## Normalization Justification

**Prompt:** *"Your manager argues that keeping everything in one table is simpler and normalization is over-engineering. Using specific examples from the dataset, defend or refute this position."*

The manager's argument has intuitive appeal — one table is easy to query, no joins are needed, and onboarding a new analyst is straightforward. However, the `orders_flat.csv` dataset vividly demonstrates that this simplicity is an illusion that collapses under the weight of real-world data management needs.

Consider the update anomaly identified above: sales representative SR01 (Deepak Joshi) has his office address stored across dozens of rows. In this 187-row excerpt alone, at least four rows already carry an abbreviated, inconsistent version — `"Nariman Pt"` instead of `"Nariman Point"`. If the company relocates SR01's office, an analyst must hunt down and update every single row touching SR01 across potentially thousands of orders. Miss even one, and queries depending on `office_address` will return contradictory results — a silent data-quality bug that is notoriously hard to detect.

The insert anomaly is equally damaging: management cannot add a new product to the catalogue, or onboard a new sales rep, without fabricating a dummy order. P008 (Webcam), which appears in only one order (ORD1185), illustrates the delete anomaly — remove that cancellation and the entire product record vanishes. A normalized schema with separate `Products`, `Customers`, `SalesReps`, and `Orders` tables eliminates all three anomalies at once. Product P008 lives in its own row in the `Products` table, independent of any order. SR01's address is stored once in `SalesReps` and updated in exactly one place.

The one-table design also scales poorly: every new order duplicates customer name, email, city, product name, category, price, rep name, rep email, and office address. With 187 rows and only 8 customers and 8 products, the redundancy is already measurable. At a million orders, storage costs and inconsistency risks multiply proportionally. Normalization is not over-engineering — it is the disciplined application of proven database theory to guarantee data integrity, reduce storage, and simplify maintenance. The perceived complexity of joins is a one-time cost that prevents compounding data-quality debt for the lifetime of the system.
