-- Hours 5 and 6: analytics marts and business KPI views.
--
-- Dimensions describe business entities.
-- Facts store measurable events such as orders and order lines.
-- KPI views answer portfolio-friendly business questions.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

CREATE OR REPLACE TABLE MARTS.DIM_CUSTOMERS AS
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    country,
    customer_segment,
    signup_date,
    marketing_opt_in,
    is_valid_email
FROM STAGING.STG_CUSTOMERS;

CREATE OR REPLACE TABLE MARTS.DIM_PRODUCTS AS
SELECT
    product_id,
    sku,
    product_name,
    category,
    brand,
    unit_price,
    active_flag
FROM STAGING.STG_PRODUCTS;

CREATE OR REPLACE TABLE MARTS.FACT_ORDER_ITEMS AS
SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.gross_item_amount,
    p.category,
    p.brand,
    p.product_name
FROM STAGING.STG_ORDER_ITEMS oi
LEFT JOIN STAGING.STG_PRODUCTS p
    ON oi.product_id = p.product_id;

CREATE OR REPLACE TABLE MARTS.FACT_ORDERS AS
WITH item_rollup AS (
    SELECT
        order_id,
        COUNT(*) AS order_item_rows,
        SUM(COALESCE(quantity, 0)) AS total_quantity,
        SUM(COALESCE(gross_item_amount, 0)) AS gross_order_amount
    FROM STAGING.STG_ORDER_ITEMS
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    o.payment_method,
    o.shipping_city,
    c.customer_segment,
    COALESCE(i.order_item_rows, 0) AS order_item_rows,
    COALESCE(i.total_quantity, 0) AS total_quantity,
    COALESCE(i.gross_order_amount, 0) AS gross_order_amount,
    o.discount_amount,
    GREATEST(COALESCE(i.gross_order_amount, 0) - o.discount_amount, 0) AS net_order_amount
FROM STAGING.STG_ORDERS o
LEFT JOIN item_rollup i
    ON o.order_id = i.order_id
LEFT JOIN STAGING.STG_CUSTOMERS c
    ON o.customer_id = c.customer_id;

CREATE OR REPLACE VIEW MARTS.V_REVENUE_BY_DAY AS
SELECT
    order_date,
    COUNT(*) AS order_count,
    SUM(net_order_amount) AS revenue,
    AVG(net_order_amount) AS average_order_value
FROM MARTS.FACT_ORDERS
WHERE status NOT IN ('cancelled', 'returned')
GROUP BY order_date;

CREATE OR REPLACE VIEW MARTS.V_TOP_PRODUCTS_BY_REVENUE AS
SELECT
    product_id,
    product_name,
    category,
    brand,
    SUM(gross_item_amount) AS revenue,
    SUM(quantity) AS units_sold,
    RANK() OVER (ORDER BY SUM(gross_item_amount) DESC) AS revenue_rank
FROM MARTS.FACT_ORDER_ITEMS
WHERE product_id IS NOT NULL
GROUP BY product_id, product_name, category, brand;

CREATE OR REPLACE VIEW MARTS.V_CUSTOMER_SEGMENT_KPIS AS
SELECT
    COALESCE(customer_segment, 'Unknown') AS customer_segment,
    COUNT(DISTINCT customer_id) AS customers_with_orders,
    COUNT(*) AS orders,
    SUM(net_order_amount) AS revenue,
    AVG(net_order_amount) AS average_order_value
FROM MARTS.FACT_ORDERS
WHERE status NOT IN ('cancelled', 'returned')
GROUP BY COALESCE(customer_segment, 'Unknown');

CREATE OR REPLACE VIEW MARTS.V_AVERAGE_ORDER_VALUE AS
SELECT
    COUNT(*) AS completed_orders,
    SUM(net_order_amount) AS revenue,
    AVG(net_order_amount) AS average_order_value
FROM MARTS.FACT_ORDERS
WHERE status NOT IN ('cancelled', 'returned');

-- Portfolio query examples.
SELECT * FROM MARTS.V_REVENUE_BY_DAY ORDER BY order_date LIMIT 10;
SELECT * FROM MARTS.V_TOP_PRODUCTS_BY_REVENUE ORDER BY revenue_rank LIMIT 10;
SELECT * FROM MARTS.V_CUSTOMER_SEGMENT_KPIS ORDER BY revenue DESC;
SELECT * FROM MARTS.V_AVERAGE_ORDER_VALUE;

-- Window function practice: revenue trend with running total.
SELECT
    order_date,
    revenue,
    SUM(revenue) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue
FROM MARTS.V_REVENUE_BY_DAY
ORDER BY order_date;

-- Task:
-- Choose one KPI view and rewrite it as an ad hoc SELECT before trusting the saved view.
--
-- Checkpoint question:
-- Why are DIM_CUSTOMERS and FACT_ORDERS separate tables?

