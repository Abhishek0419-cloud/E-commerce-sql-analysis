# SQL Business Queries: E-commerce Sales Analysis

52 business questions answered in MySQL on a sample e-commerce database (customers, products, orders, order items). The queries cover revenue, products, customers, retention, churn and RFM segmentation, using joins, CTEs and window functions.

**Tools:** MySQL 8 · **Skills shown:** multi-table joins, CTEs, window functions, cohort-style logic, data validation

> **Note on the data:** the dataset is a synthetic sample (90 customers, 38 products, 2,000 orders), built for practice. Numbers below show that the queries work, not real business performance. For example, every customer in this data makes repeat purchases, which real data would not.

## Dataset

| Table | Rows | Description |
|---|---|---|
| `customers` | 90 | Name, city, gender, signup date |
| `products` | 38 | Name, category (7 categories), unit price |
| `orders` | 2,000 | Order date and status (Delivered 1,649 · Cancelled 240 · Pending 111) |
| `order_items` | 4,967 | Product, quantity and price per order line |

- Period: **1 Jan 2025 – 25 Jul 2026**.
- 10 customers have never placed an order.

## Rules used in every query

These rules fix the most common mistakes in the first version of my queries:

1. **Cancelled orders are not revenue.** Revenue, sales and units use only `order_status = 'Delivered'`. Counting all orders gave 39.55M, which was about 7.3M too high; delivered revenue is 32.28M.
2. **Customer behaviour questions** (repeat purchases, gaps, activity, churn, RFM) use orders that are not cancelled.
3. **"Today" is the last order date in the data, not `CURDATE()`.** The data ends in July 2026, so `CURDATE()` made every customer look churned (churn rate 100%). Anchored to the last order date, churn is 16.25%.
4. **Date gaps use `DATEDIFF()`.** In MySQL, `date1 - date2` subtracts the numbers, so `2025-03-01 − 2025-02-28` returns 73 instead of 1 day.

## Query index

| Section | Questions | Examples |
|---|---|---|
| Business KPIs | 1–5 | Total revenue, orders, customers, products, average order value |
| Products and categories | 6, 7, 14–16, 22, 28, 42, 48, 49, 52 | Best and worst sellers, revenue per category, top product in each category, % contribution to revenue |
| Customers and value | 8, 19, 21, 27, 30, 31, 43, 44 | Top customers, ranking, highest-value order, lifetime value, revenue by gender |
| Geography | 10, 20 | Top cities by revenue |
| Time trends | 9, 23, 29, 41, 50 | Monthly revenue, running total, month-over-month growth, best month |
| Orders and cancellations | 17, 18, 46, 47 | Basket size, large orders, cancellation rate, delivered vs cancelled |
| Repeat purchase and retention | 11, 12, 24–26, 32–35, 37, 51 | Repeat customers, never-ordered customers, gaps between orders, new vs returning, active customers per month |
| Churn and segmentation | 13, 39, 40, 45 | Inactive and at-risk customers, churn rate, RFM scores and segments |
| Basket and growth | 36, 38 | Products bought together, fastest-growing category |

## Selected results

| Question | Result |
|---|---|
| Total revenue (delivered) | **32,280,641** |
| Average order value | 19,575.89 |
| Cancellation rate | 12.00% |
| Top category by revenue | Electronics, **63.4%** of revenue (Home & Kitchen 12.8%, Clothing 10.7%) |
| Top product by units | Badminton Racket (388 units) |
| Top city by revenue | Delhi (4,658,534) |
| Top customer by revenue | Anil Verma (1,292,250) |
| Revenue split | Male 52.9% · Female 47.1% |
| Monthly orders | 40 (Jan 2025) rising to 249 (Jul 2026) |
| Average days between a customer's orders | 15.4 |
| Churn rate (no order in last 60 days of data) | 16.25% (13 of 80 customers) |
| Fastest-growing category (last 90 days vs previous 90) | Beauty, +158.7% |
| Most frequent product pair | Mechanical Keyboard + Fiction Novel Pack (14 orders) |
| RFM segments | Champions 17 · Loyal 18 · At risk 13 · Lost 19 · Other 13 |

## SQL techniques used

Multi-table joins, `LEFT JOIN` anti-join (customers with no orders), CTEs, window functions (`LAG`, `LEAD`, `DENSE_RANK`, `NTILE`, running `SUM() OVER`), conditional aggregation (`CASE WHEN`), self-join for product pairs, subqueries, date functions (`DATE_FORMAT`, `DATEDIFF`, `DATE_SUB`).

## How I checked the queries

- Ran all 52 queries on the full dataset without errors (tested on MariaDB 10.11, which is MySQL-compatible; written for MySQL 8).
- Cross-checked key results (revenue, AOV, category shares, churn, repeat rate, growth) against an independent calculation in Python.
- Checked that the 10 customers without orders and the order-status counts match the raw data.

## Limitations

- Synthetic data, so findings are for practice and do not describe a real business.
- Month-over-month growth for July 2026 compares a partial month (data ends 25 July).
- The fastest-growing category query ignores categories with fewer than 30 orders in the earlier period; the threshold of 30 is a judgement call.
- Churn uses a 60-day window. A different window changes the rate.

## How to run

1. Install MySQL 8 or later.
2. Load the dataset (creates the `E_Commerce_Project` database and all tables):
```bash
   mysql -u root -p < ecommerce_dataset_updated.sql
```
3. Run the queries in MySQL Workbench or the command line:
```bash
   mysql -u root -p < ecommerce_52_queries_corrected.sql
```

## Repository contents

- `ecommerce_dataset_updated.sql`: schema and sample data
- `ecommerce_52_queries_corrected.sql`: all 52 queries, numbered and commented
