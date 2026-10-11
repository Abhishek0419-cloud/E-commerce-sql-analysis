-- =====================================================================
-- E-commerce Sales Analysis - 52 business questions (corrected, MySQL 8)
-- Dataset: 90 customers | 38 products | 2,000 orders | 4,967 order items
-- Period : 2025-01-01 to 2026-07-25 (data is synthetic / sample data)
--
-- RULES USED IN EVERY QUERY
--  1. Cancelled orders are NOT revenue. Revenue, sales and units use only
--     order_status = 'Delivered'. (Original queries counted all orders, so
--     revenue was overstated: 39.55M with cancelled vs 32.28M delivered.)
--  2. Customer-behaviour questions (repeat, gaps, active, churn, RFM)
--     use orders that are not cancelled (order_status <> 'Cancelled').
--  3. "Today" is the last order date in the data, NOT CURDATE(). With
--     CURDATE() the churn rate is 100% (today is far after the data ends)
--     and "new vs returning in the last 7 days" returns no rows.
--  4. Date gaps use DATEDIFF(). In MySQL, date1 - date2 subtracts the
--     numbers 20250301 - 20250228 = 73, not days.
-- =====================================================================

USE E_Commerce_Project;

-- 1 What is our total revenue so far?   -> 32,280,641 (delivered orders)
SELECT SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered';

-- 2 How many total orders have we received?   -> 2,000 (all statuses)
SELECT COUNT(*) AS total_orders FROM orders;

-- 3 How many total customers do we have?   -> 90
SELECT COUNT(*) AS total_customers FROM customers;

-- 4 How many total products do we sell?   -> 38
SELECT COUNT(*) AS total_products FROM products;

-- 5 Average amount a customer spends per order (AOV, delivered orders)
SELECT ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT oi.order_id), 2) AS aov
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered';

-- 6 Top 5 best-selling products (units)
SELECT p.product_id, p.product_name, SUM(oi.quantity) AS total_units_sold
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name
ORDER BY total_units_sold DESC
LIMIT 5;

-- 7 Which category generates the most revenue?
SELECT p.category, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC
LIMIT 1;

-- 8 Top 5 most valuable customers
SELECT o.customer_id, c.customer_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN customers c   ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id  = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY o.customer_id, c.customer_name
ORDER BY revenue DESC
LIMIT 5;

-- 9 Revenue trend month by month
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
       SUM(oi.quantity * oi.unit_price)   AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month;

-- 10 Which city generates the most sales?
SELECT c.city, SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.city
ORDER BY revenue DESC
LIMIT 1;

-- 11 Which customers purchase repeatedly? (orders count and shortest gap)
SELECT customer_id,
       COUNT(*)                                   AS total_orders,
       MIN(DATEDIFF(next_order, order_date))      AS shortest_gap_days
FROM (
    SELECT customer_id, order_date,
           LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order
    FROM orders
    WHERE order_status <> 'Cancelled'
) t
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY total_orders DESC;

-- 12 Which customers have never placed an order?   -> 10 customers
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL;

-- 13 Which customers have been inactive for more than 90 days?
--    (measured from the last order date in the data)   -> 6 customers
SELECT customer_id,
       MAX(order_date) AS last_order,
       DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(order_date)) AS days_inactive
FROM orders
WHERE order_status <> 'Cancelled'
GROUP BY customer_id
HAVING days_inactive > 90
ORDER BY days_inactive DESC;

-- 14 Best-selling category (units)
SELECT p.category, SUM(oi.quantity) AS total_units_sold
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o       ON o.order_id    = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY total_units_sold DESC
LIMIT 1;

-- 15 Product with the highest revenue
SELECT p.product_id, p.product_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o       ON o.order_id    = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC
LIMIT 1;

-- 16 Product with the lowest revenue (among products that sold)
SELECT p.product_id, p.product_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o       ON o.order_id    = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name
ORDER BY revenue ASC
LIMIT 1;

-- 17 Average number of products bought per order (line items and units)
SELECT ROUND(AVG(line_items), 2) AS avg_products_per_order,
       ROUND(AVG(units), 2)      AS avg_units_per_order
FROM (
    SELECT oi.order_id, COUNT(*) AS line_items, SUM(oi.quantity) AS units
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY oi.order_id
) t;

-- 18 Orders worth more than 10,000
SELECT oi.order_id, o.order_status, SUM(oi.quantity * oi.unit_price) AS order_value
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY oi.order_id, o.order_status
HAVING order_value > 10000
ORDER BY order_value DESC;

-- 19 Customers with the highest average order value (top 10)
SELECT c.customer_id, c.customer_name,
       COUNT(DISTINCT oi.order_id) AS orders,
       ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT oi.order_id), 2) AS aov
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name
ORDER BY aov DESC
LIMIT 10;

-- 20 Top 3 cities by revenue
SELECT c.city, SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.city
ORDER BY revenue DESC
LIMIT 3;

-- 21 Customers ranked by revenue
SELECT customer_id, revenue, DENSE_RANK() OVER (ORDER BY revenue DESC) AS ranking
FROM (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
) t
ORDER BY ranking;

-- 22 Top-selling product in each category (units)
WITH product_sales AS (
    SELECT p.category, p.product_id, p.product_name, SUM(oi.quantity) AS total_units_sold
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    JOIN orders o       ON o.order_id    = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.category, p.product_id, p.product_name
),
ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY category ORDER BY total_units_sold DESC) AS ranking
    FROM product_sales
)
SELECT * FROM ranked WHERE ranking = 1 ORDER BY category;

-- 23 Revenue accumulated over time (running total by day)
SELECT order_date, daily_revenue,
       SUM(daily_revenue) OVER (ORDER BY order_date) AS running_revenue
FROM (
    SELECT o.order_date, SUM(oi.quantity * oi.unit_price) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.order_date
) t
ORDER BY order_date;

-- 24 When was each customer's previous order placed?
SELECT customer_id, order_date,
       LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order
FROM orders
WHERE order_status <> 'Cancelled'
ORDER BY customer_id, order_date;

-- 25 When was each customer's next order placed, if any?
SELECT customer_id, order_date,
       LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order
FROM orders
WHERE order_status <> 'Cancelled'
ORDER BY customer_id, order_date;

-- 26 Days between a customer's consecutive orders
SELECT customer_id, order_date, days_between_orders
FROM (
    SELECT customer_id, order_date,
           DATEDIFF(order_date,
                    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS days_between_orders
    FROM orders
    WHERE order_status <> 'Cancelled'
) t
WHERE days_between_orders IS NOT NULL
ORDER BY customer_id, order_date;

-- 27 Top 3 customers by revenue
SELECT *
FROM (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS revenue,
           DENSE_RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS ranking
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
) t
WHERE ranking <= 3;

-- 28 % each product contributes to total revenue
SELECT product_id, revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS revenue_pct
FROM (
    SELECT oi.product_id, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY oi.product_id
) t
ORDER BY revenue_pct DESC;

-- 29 Month-over-month revenue growth
--    (2026-07 is a partial month: data ends on 25 July)
WITH monthly_revenue AS (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
           SUM(oi.quantity * oi.unit_price)   AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
with_prev AS (
    SELECT order_month, revenue,
           LAG(revenue) OVER (ORDER BY order_month) AS previous_revenue
    FROM monthly_revenue
)
SELECT order_month, revenue, previous_revenue,
       ROUND(100 * (revenue - previous_revenue) / previous_revenue, 2) AS mom_growth_pct
FROM with_prev
ORDER BY order_month;

-- 30 Each customer's highest-value order
WITH order_totals AS (
    SELECT o.customer_id, oi.order_id, SUM(oi.quantity * oi.unit_price) AS order_value
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id, oi.order_id
),
ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_value DESC) AS ranking
    FROM order_totals
)
SELECT customer_id, order_id, order_value
FROM ranked
WHERE ranking = 1
ORDER BY customer_id;

-- 31 Customer lifetime value (CLV = delivered revenue per customer)
SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS lifetime_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY o.customer_id
ORDER BY lifetime_value DESC;

-- 32 % of customers who make repeat purchases
--    (among customers with at least one non-cancelled order)
SELECT ROUND(100 * SUM(order_count > 1) / COUNT(*), 2) AS repeat_customer_pct
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    WHERE order_status <> 'Cancelled'
    GROUP BY customer_id
) t;

-- 33 New vs returning customers in the last 30 days of data
--    New = first-ever order falls inside the window.
WITH ref AS (SELECT MAX(order_date) AS max_d FROM orders),
first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order
    FROM orders WHERE order_status <> 'Cancelled'
    GROUP BY customer_id
),
recent AS (
    SELECT DISTINCT o.customer_id
    FROM orders o CROSS JOIN ref r
    WHERE o.order_status <> 'Cancelled'
      AND o.order_date > DATE_SUB(r.max_d, INTERVAL 30 DAY)
)
SELECT CASE WHEN f.first_order > DATE_SUB(r.max_d, INTERVAL 30 DAY)
            THEN 'New' ELSE 'Returning' END AS customer_type,
       COUNT(*) AS customer_count
FROM recent
JOIN first_orders f ON f.customer_id = recent.customer_id
CROSS JOIN ref r
GROUP BY customer_type;

-- 34 Active customers each month
SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month,
       COUNT(DISTINCT customer_id) AS active_customers
FROM orders
WHERE order_status <> 'Cancelled'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;

-- 35 Customers who purchase from more than one category
SELECT o.customer_id, COUNT(DISTINCT p.category) AS categories_bought
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY o.customer_id
HAVING categories_bought > 1
ORDER BY categories_bought DESC, o.customer_id;

-- 36 Products most frequently purchased together (top 5 pairs)
SELECT p1.product_name AS product_1, p2.product_name AS product_2,
       COUNT(*) AS times_together
FROM order_items a
JOIN order_items b ON a.order_id = b.order_id AND a.product_id < b.product_id
JOIN orders o      ON o.order_id = a.order_id
JOIN products p1   ON p1.product_id = a.product_id
JOIN products p2   ON p2.product_id = b.product_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p1.product_name, p2.product_name
ORDER BY times_together DESC
LIMIT 5;

-- 37 Average days between a customer's orders
WITH gaps AS (
    SELECT customer_id,
           DATEDIFF(order_date,
                    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS gap_days
    FROM orders
    WHERE order_status <> 'Cancelled'
)
SELECT ROUND(AVG(gap_days), 1) AS avg_days_between_orders
FROM gaps
WHERE gap_days IS NOT NULL;

-- 38 Which category is growing the fastest?
--    Orders in the last 90 days of data vs the 90 days before that.
--    Categories with fewer than 30 orders in the earlier period are ignored
--    (tiny bases give meaningless growth rates).
WITH ref AS (SELECT MAX(order_date) AS max_d FROM orders),
cat AS (
    SELECT p.category,
           COUNT(DISTINCT CASE WHEN o.order_date > DATE_SUB(r.max_d, INTERVAL 90 DAY)
                               THEN o.order_id END) AS recent_orders,
           COUNT(DISTINCT CASE WHEN o.order_date >  DATE_SUB(r.max_d, INTERVAL 180 DAY)
                                AND o.order_date <= DATE_SUB(r.max_d, INTERVAL 90 DAY)
                               THEN o.order_id END) AS prior_orders
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    JOIN orders o   ON o.order_id   = oi.order_id
    CROSS JOIN ref r
    WHERE o.order_status <> 'Cancelled'
    GROUP BY p.category
)
SELECT category, recent_orders, prior_orders,
       ROUND(100 * (recent_orders - prior_orders) / prior_orders, 1) AS growth_pct
FROM cat
WHERE prior_orders >= 30
ORDER BY growth_pct DESC;

-- 39 Customers at risk of churn (no order in the last 60 days of data)
SELECT customer_id, MAX(order_date) AS last_order,
       DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(order_date)) AS days_since_last_order
FROM orders
WHERE order_status <> 'Cancelled'
GROUP BY customer_id
HAVING days_since_last_order > 60
ORDER BY days_since_last_order DESC;

-- 40 RFM analysis with scores (5 = best) and simple segments
WITH rfm AS (
    SELECT o.customer_id,
           DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(o.order_date)) AS recency_days,
           COUNT(DISTINCT o.order_id)                                       AS frequency,
           SUM(oi.quantity * oi.unit_price)                                 AS monetary
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency)         AS f_score,
           NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM rfm
)
SELECT customer_id, recency_days, frequency, monetary, r_score, f_score, m_score,
       CASE WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At risk'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
            ELSE 'Other' END AS segment
FROM scored
ORDER BY monetary DESC;

-- 41 Daily sales trend
SELECT o.order_date, SUM(oi.quantity * oi.unit_price) AS daily_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY o.order_date
ORDER BY o.order_date;

-- 42 Top 10 best-selling products
SELECT oi.product_id, p.product_name, SUM(oi.quantity) AS total_units_sold
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY oi.product_id, p.product_name
ORDER BY total_units_sold DESC
LIMIT 10;

-- 43 Top 10 customers by revenue
SELECT o.customer_id, c.customer_name, SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM order_items oi
JOIN orders o    ON o.order_id    = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY o.customer_id, c.customer_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 44 Revenue from male vs female customers
SELECT c.gender, SUM(oi.quantity * oi.unit_price) AS total_revenue,
       ROUND(100 * SUM(oi.quantity * oi.unit_price) / SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 1) AS pct
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.gender
ORDER BY total_revenue DESC;

-- 45 Customer churn rate
--    Churned = no non-cancelled order in the last 60 days of data.
--    Denominator = customers with at least one non-cancelled order.   -> 16.25% (13 of 80)
WITH last_orders AS (
    SELECT customer_id, MAX(order_date) AS last_order
    FROM orders
    WHERE order_status <> 'Cancelled'
    GROUP BY customer_id
)
SELECT ROUND(100 * SUM(DATEDIFF((SELECT MAX(order_date) FROM orders), last_order) > 60) / COUNT(*), 2)
       AS churn_rate_pct
FROM last_orders;

-- 46 % of orders that get cancelled   -> 12.00%
SELECT ROUND(100 * SUM(order_status = 'Cancelled') / COUNT(*), 2) AS cancelled_pct
FROM orders;

-- 47 Orders delivered vs cancelled
SELECT order_status, COUNT(*) AS total_orders
FROM orders
WHERE order_status IN ('Cancelled', 'Delivered')
GROUP BY order_status;

-- 48 Worst-selling category (units)
SELECT p.category, SUM(oi.quantity) AS total_units_sold
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY total_units_sold ASC
LIMIT 1;

-- 49 Most expensive product sold (delivered)
SELECT p.product_id, p.product_name, p.unit_price AS price
FROM products p
WHERE p.product_id IN (
    SELECT oi.product_id
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
)
ORDER BY p.unit_price DESC
LIMIT 1;

-- 50 Month with the highest revenue
SELECT YEAR(o.order_date) AS order_year, MONTH(o.order_date) AS order_month,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY revenue DESC
LIMIT 1;

-- 51 New customers acquired each month (by signup date; includes customers who never ordered)
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS signup_month, COUNT(*) AS new_customers
FROM customers
GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
ORDER BY signup_month;

-- 52 % each category contributes to total revenue
SELECT p.category,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       ROUND(100 * SUM(oi.quantity * oi.unit_price) / SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 2) AS revenue_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;
