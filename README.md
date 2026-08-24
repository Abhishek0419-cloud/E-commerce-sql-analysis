# E-Commerce SQL Analysis

SQL analysis of an e-commerce dataset using MySQL to answer real-world business questions related to sales, customers, products, revenue, and customer behavior.

## About the Project

This project focuses on analyzing an e-commerce database using SQL.

I worked through 50+ business questions, starting with basic metrics such as total revenue and orders, and then moving into more advanced analysis using joins, subqueries, CTEs, window functions, and date functions.

The main goal was to practice writing SQL queries that can be used to answer practical business questions rather than just performing basic data retrieval.

## Tools Used

- MySQL
- SQL
- MySQL Workbench

## Database Tables

The analysis uses the following tables:

- `customers` – customer information
- `orders` – order details and order dates
- `order_items` – products purchased in each order
- `products` – product details, categories, and prices

## Analysis Covered

### Sales & Revenue
- Total revenue
- Total orders
- Average order value
- Monthly revenue trends
- Daily sales trends
- Running revenue total
- Highest-revenue month
- Revenue contribution by product and category
- Month-over-month revenue growth

### Product Analysis
- Top-selling products
- Highest and lowest revenue-generating products
- Best-selling category
- Worst-selling category
- Top-selling product in each category
- Most expensive product sold
- Products frequently purchased together

### Customer Analysis
- Top customers by revenue
- Customer revenue ranking
- Customer lifetime value (CLV)
- Average order value by customer
- Repeat customers
- Customers who never placed an order
- Customer activity by month
- New vs returning customers
- Customers purchasing across multiple categories

### Customer Retention & Churn
- Inactive customers
- Customers at risk of churn
- Customer churn rate
- Average time between customer orders
- RFM analysis (Recency, Frequency, Monetary)

### Other Analysis
- Revenue by city
- Top cities by revenue
- Revenue by gender
- Cancelled order percentage
- Delivered vs cancelled orders

## SQL Concepts Practiced

This project helped me practice:

- `SELECT`, `WHERE`, `GROUP BY`, `HAVING`
- Aggregate functions such as `SUM()`, `COUNT()`, and `AVG()`
- `INNER JOIN` and `LEFT JOIN`
- Subqueries
- Common Table Expressions (CTEs)
- Window functions
- `LAG()` and `LEAD()`
- `DENSE_RANK()`
- Date and time functions
- Conditional filtering
- Revenue and percentage calculations
- Customer segmentation
- Running totals
- Month-over-month analysis

## Example Query

### Top 3 Customers by Revenue

```sql
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
