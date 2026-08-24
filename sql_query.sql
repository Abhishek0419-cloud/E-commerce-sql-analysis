use e_commerce_project;

-- 1 What is our total revenue so far?
SELECT 
    SUM(quantity * unit_price) AS revenue
FROM
    order_items;

-- 2 How many total orders have we received?
SELECT 
    COUNT(*)as total_orders
FROM
    orders;

-- 3 How many total customers do we have?
SELECT 
    COUNT(*) as total_customers
FROM
    customers;

-- 4 How many total products do we sell?
SELECT 
    COUNT(*)as total_products
FROM
    products;

-- 5 What is the average amount a customer spends per order?
SELECT 
    (SUM(quantity * unit_price) / COUNT(DISTINCT order_id)) AS aov
FROM
    order_items;

-- 6 What are the top 5 best-selling products?
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_units_sold
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
GROUP BY p.product_id , p.product_name
ORDER BY total_units_sold DESC
LIMIT 5;

--  7 Which category is generating the most revenue?
SELECT 
    p.category, SUM(o.quantity * o.unit_price) AS revenue
FROM
    products p
        JOIN
    order_items o ON p.product_id = o.product_id
GROUP BY p.category
ORDER BY revenue DESC
LIMIT 1;

-- 8 Who are our top 5 most valuable customers?
SELECT 
    c.customer_id, SUM(oi.quantity * oi.unit_price) AS revenue
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id
ORDER BY revenue DESC
LIMIT 5;

-- 9 How has our revenue trended month by month?
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month;

-- 10 Which city is generating the most sales?
SELECT 
    c.city, SUM(quantity * unit_price) AS rev
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON oi.order_id = o.order_id
GROUP BY c.city
ORDER BY rev DESC
LIMIT 1;

-- 11 Which customers purchase repeatedly?
SELECT
    customer_id,
    MIN(second_order - order_date) AS diff
FROM (
    SELECT
        c.customer_id,
        o.order_date,
        LEAD(o.order_date) OVER (
            PARTITION BY c.customer_id
            ORDER BY o.order_date
        ) AS second_order
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
) t
WHERE second_order IS NOT NULL
GROUP BY customer_id
ORDER BY diff ASC;

-- or 

SELECT
    customer_id,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) > 1;

-- 12 Which customers have never placed an order?
SELECT 
    c.customer_id, c.customer_name
FROM
    customers c
        LEFT JOIN
    orders o ON c.customer_id = o.customer_id
WHERE
    o.customer_id IS NULL;

-- 13 Which customers have been inactive in the last 90 days?
SELECT 
    o.customer_id,
    MAX(order_date),
    DATEDIFF(CURRENT_DATE(), MAX(order_date))AS days_inactive
FROM
    orders o
GROUP BY customer_id
HAVING DATEDIFF(CURRENT_DATE(), MAX(order_date)) > 90
ORDER BY customer_id;

-- 14 What is the best-selling category?
SELECT
    p.category,
    SUM(oi.quantity) AS total_units_sold
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_units_sold DESC
LIMIT 1;

-- 15 Which product generates the highest revenue?
SELECT 
    p.product_id,
    p.product_name,
    SUM(o.quantity * o.unit_price) AS rev
FROM
    products p
        JOIN
    order_items o ON p.product_id = o.product_id
GROUP BY p.product_id , p.product_name
ORDER BY rev DESC
LIMIT 1;

-- 16 Which product generates the lowest revenue?
SELECT 
    p.product_id,
    p.product_name,
    SUM(o.quantity * o.unit_price) AS rev
FROM
    products p
        JOIN
    order_items o ON p.product_id = o.product_id
GROUP BY p.product_id , p.product_name
ORDER BY rev ASC
LIMIT 1;

-- 17 On average, how many products are bought per order?
SELECT 
    AVG(product_count)as avg_products_per_order
FROM
    (SELECT 
        order_id, COUNT(*) AS product_count
    FROM
        order_items
    GROUP BY order_id) t;

-- 18 Which orders are worth more than 10,000?
SELECT 
    order_id, SUM(quantity * unit_price) AS rev
FROM
    order_items
GROUP BY order_id
HAVING rev > 10000;

-- 19 Which customers have the highest average order value?
SELECT 
    c.customer_id,
    c.customer_name,
    (SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT oi.order_id)) AS aov
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id , c.customer_name
ORDER BY aov DESC;

-- 20 What are the top 3 cities by revenue?
SELECT 
    c.city, SUM(oi.quantity * oi.unit_price) AS rev
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY c.city
ORDER BY rev DESC
LIMIT 3;

-- 21 How are customers ranked based on revenue?
SELECT
    *,
    DENSE_RANK() OVER (
        ORDER BY rev DESC
    ) AS ranking
FROM (
    SELECT
        c.customer_id,
        SUM(quantity * unit_price) AS rev
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_id
) t;

-- 22 What is the top-selling product in each category?
WITH product_sales AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_units_sold
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_id, p.product_name
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY total_units_sold DESC
        ) AS ranking
    FROM product_sales
)
SELECT *
FROM ranked
WHERE ranking = 1;

-- 23 How has our revenue accumulated over time — running total?
SELECT
    order_date,
    SUM(daily_rev) OVER (
        ORDER BY order_date
    ) AS running_rev
FROM (
    SELECT
        o.order_date,
        SUM(oi.quantity * oi.unit_price) AS daily_rev
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    GROUP BY o.order_date
) t;

-- 24 When was each customer's previous order placed?
SELECT
    customer_id,
    order_date,
    LAG(order_date) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS previous_order
FROM orders;

-- 25 When was each customer's next order placed, if any?
SELECT
    customer_id,
    order_date,
    LEAD(order_date) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS next_order
FROM orders;

-- 26 How many days are there between a customer's consecutive orders?
SELECT
    customer_id,
    DATEDIFF(
        LEAD(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ),
        order_date
    ) AS days_between_orders
FROM orders;

-- 27 Who are the top 3 customers by revenue?
SELECT *
FROM (
    SELECT
        *,
        DENSE_RANK() OVER (
            ORDER BY rev DESC
        ) AS ranking
    FROM (
        SELECT
            o.customer_id,
            SUM(oi.quantity * oi.unit_price) AS rev
        FROM order_items oi
        JOIN orders o
            ON o.order_id = oi.order_id
        GROUP BY o.customer_id
    ) t
) s
WHERE ranking <= 3;


-- 28 What percentage does each product contribute to total revenue?
SELECT 
    product_id,
    rev,
    rev / SUM(rev) OVER () * 100 AS revenue_percentage
FROM (
    SELECT 
        product_id,
        SUM(quantity * unit_price) AS rev
    FROM order_items
    GROUP BY product_id
) t;

-- 29 What is the month-over-month revenue growth?
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
revenue_with_previous AS (
    SELECT
        order_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY order_month
        ) AS previous_revenue
    FROM monthly_revenue
)
SELECT
    order_month,
    revenue,
    (revenue - previous_revenue)
        / previous_revenue * 100 AS mom_growth
FROM revenue_with_previous;

-- 30 What was each customer's highest-value order?
WITH ranked AS (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY customer_id
               ORDER BY order_val DESC
           ) AS ranking
    FROM (
        SELECT 
            o.customer_id,
            oi.order_id,
            SUM(oi.quantity * oi.unit_price) AS order_val
        FROM order_items oi
        JOIN orders o 
            ON o.order_id = oi.order_id
        GROUP BY oi.order_id, o.customer_id
    ) t
)
SELECT *
FROM ranked
WHERE ranking = 1;

-- 31 What is each customer's lifetime value — CLV?
SELECT
    o.customer_id,
    SUM(oi.quantity * oi.unit_price) AS lifetime_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY o.customer_id;

-- 32 What percentage of customers make repeat purchases?
SELECT
    COUNT(*) * 100.0 /
    (
        SELECT COUNT(DISTINCT customer_id)
        FROM orders
    ) AS repeat_order_percentage
FROM (
    SELECT
        customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) t;


-- 33 How many customers are new vs returning?
WITH order_history AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS previous_order_date
    FROM orders
),
customer_type AS (
    SELECT
        customer_id,
        CASE
            WHEN previous_order_date IS NULL
                THEN 'New'
            ELSE 'Returning'
        END AS customer_type
    FROM order_history
    WHERE order_date >= CURDATE() - INTERVAL 7 DAY
)
SELECT
    customer_type,
    COUNT(DISTINCT customer_id) AS customer_count
FROM customer_type
GROUP BY customer_type;

-- 34 How many customers were active each month?
SELECT
    MONTH(order_date) AS order_month,
    YEAR(order_date) AS order_year,
    COUNT(DISTINCT customer_id) AS active_customers
FROM orders
GROUP BY
    MONTH(order_date),
    YEAR(order_date)
ORDER BY
    order_year,
    order_month;
    
-- 35 Which customers purchase from more than one category?
SELECT
    o.customer_id,
    COUNT(DISTINCT p.category) AS order_cat
FROM order_items oi
JOIN products p
    ON p.product_id = oi.product_id
JOIN orders o
    ON o.order_id = oi.order_id
GROUP BY o.customer_id
HAVING order_cat > 1
ORDER BY o.customer_id;

-- 36 Which two products are most frequently purchased together?
SELECT
    oi.product_id AS p1,
    oi2.product_id AS p2,
    COUNT(*) AS times_purchased_together
FROM order_items oi
JOIN order_items oi2
    ON oi.order_id = oi2.order_id
    AND oi.product_id < oi2.product_id
GROUP BY
    oi.product_id,
    oi2.product_id
ORDER BY times_purchased_together DESC
LIMIT 1;

-- 37 On average, how many days pass between a customer's orders?
SELECT
    AVG(order_diff)
FROM (
    SELECT
        o.customer_id,
        o.order_date,
        DATEDIFF(
            LEAD(o.order_date) OVER (
                PARTITION BY o.customer_id
                ORDER BY o.order_date
            ),
            o.order_date
        ) AS order_diff
    FROM orders o
) t;

-- or

WITH order_gaps AS (
    SELECT
        customer_id,
        DATEDIFF(
            LEAD(order_date) OVER (
                PARTITION BY customer_id
                ORDER BY order_date
            ),
            order_date
        ) AS order_diff
    FROM orders
)
SELECT
    AVG(order_diff) AS avg_days_between_orders
FROM order_gaps
WHERE order_diff IS NOT NULL;

-- 38 Which product category is growing the fastest?
WITH monthly_orders AS (
    SELECT
        p.category,
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON o.order_id = oi.order_id
    GROUP BY
        p.category,
        YEAR(o.order_date),
        MONTH(o.order_date)
),
growth AS (
    SELECT
        category,
        order_year,
        order_month,
        total_orders,
        LAG(total_orders) OVER (
            PARTITION BY category
            ORDER BY order_year, order_month
        ) AS previous_orders
    FROM monthly_orders
)
SELECT
    category,
    order_year,
    order_month,
    total_orders,
    previous_orders,
    ((total_orders - previous_orders) * 100.0 / previous_orders)
        AS growth_percentage
FROM growth
WHERE previous_orders IS NOT NULL
ORDER BY growth_percentage DESC
LIMIT 1;

-- or

WITH monthly_orders AS (
    SELECT
        p.category,
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON o.order_id = oi.order_id
    GROUP BY
        p.category,
        YEAR(o.order_date),
        MONTH(o.order_date)
),
growth AS (
    SELECT
        *,
        LAG(total_orders) OVER (
            PARTITION BY category
            ORDER BY order_year, order_month
        ) AS previous_orders
    FROM monthly_orders
)
SELECT
    category,
    order_year,
    order_month,
    total_orders,
    previous_orders,
    (total_orders - previous_orders)
        / previous_orders * 100 AS growth_percentage
FROM growth
WHERE previous_orders IS NOT NULL
ORDER BY growth_percentage DESC
LIMIT 1;

-- 39 Which customers are at risk of churn?
SELECT 
    customer_id, DATEDIFF(CURDATE(), latest_order) AS diff
FROM
    (SELECT 
        customer_id, MAX(order_date) AS latest_order
    FROM
        orders
    GROUP BY customer_id) t
WHERE
    DATEDIFF(CURDATE(), latest_order) > 60
ORDER BY customer_id;

-- 40 How do customers look based on RFM — Recency, Frequency, Monetary — analysis?
SELECT
    o.customer_id,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS recency,
    COUNT(DISTINCT o.order_id) AS frequency,
    SUM(oi.quantity * oi.unit_price) AS monetary
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id;


-- 41 What is the daily sales trend?
SELECT 
    o.order_date, SUM(oi.quantity * oi.unit_price) AS daily_revenue
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_date
ORDER BY o.order_date;

-- 42 What are the top 10 best-selling products?
SELECT 
    product_id, SUM(quantity) AS total_units_sold
FROM
    order_items
GROUP BY product_id
ORDER BY total_units_sold DESC
LIMIT 10;

-- 43 Who are the top 10 customers by revenue?
SELECT 
    o.customer_id, SUM(oi.quantity * oi.unit_price) AS total_rev
FROM
    order_items oi
        JOIN
    orders o ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY total_rev DESC
LIMIT 10;

-- 44 How much revenue comes from male vs female customers?)
SELECT 
    c.gender, SUM(oi.quantity * oi.unit_price) AS total_rev
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON oi.order_id = o.order_id
GROUP BY c.gender
ORDER BY total_rev desc;

-- 45 What is our customer churn rate?
with churn_cus as (SELECT 
    customer_id, DATEDIFF(CURDATE(), latest_order) AS diff
FROM
    (SELECT 
        customer_id, MAX(order_date) AS latest_order
    FROM
        orders
    GROUP BY customer_id) t
WHERE
    DATEDIFF(CURDATE(), latest_order) > 60)

SELECT 
    COUNT(*) / (SELECT 
            COUNT(DISTINCT customer_id)
        FROM
            orders) * 100.0 AS churn_rate
FROM
    churn_cus;
    
-- 46 What percentage of orders get cancelled?
WITH cancelled_orders AS (
    SELECT
        COUNT(*) AS cancelled
    FROM orders
    WHERE order_status = 'Cancelled'
)
SELECT
    cancelled / (SELECT COUNT(*) FROM orders) * 100.0
        AS cancelled_percentage
FROM cancelled_orders;

-- 47 How many orders were delivered vs cancelled?
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status IN ('Cancelled', 'Delivered')
GROUP BY order_status;

-- 48 What is the worst-selling category?
SELECT 
    p.category, SUM(oi.quantity) AS total_units_sold
FROM
    order_items oi join products p on p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_units_sold asc
LIMIT 1;


-- 49 What is the most expensive product sold?
SELECT 
    product_id, unit_price as highest_selling_price
FROM
    products
WHERE
    product_id IN (SELECT 
            product_id
        FROM
            order_items)
ORDER BY unit_price DESC
LIMIT 1;

-- 50 Which month had the highest revenue?
SELECT 
    MONTH(o.order_date) AS order_month,
    YEAR(o.order_date) AS order_year,
    SUM(oi.quantity * oi.unit_price) AS rev
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY MONTH(o.order_date) , YEAR(o.order_date)
ORDER BY rev DESC
LIMIT 1;

-- 51 How many new customers were acquired each month?
SELECT 
    DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
    COUNT(customer_id) AS new_customers
FROM customers
GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
ORDER BY signup_month;


-- 52 What percentage does each category contribute to total revenue?
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) /
    (
        SELECT SUM(quantity * unit_price)
        FROM order_items
    ) * 100 AS revenue_percentage
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category;