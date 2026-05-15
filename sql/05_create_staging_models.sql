-- Hour 4: staging transformations.
--
-- Staging views clean names, cast types, deduplicate by business key, and expose validation flags.
-- Views keep this lab light: they do not store another full copy of the data.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

CREATE OR REPLACE VIEW STAGING.STG_CUSTOMERS AS
SELECT
    TRIM(customer_id) AS customer_id,
    INITCAP(TRIM(first_name)) AS first_name,
    INITCAP(TRIM(last_name)) AS last_name,
    LOWER(TRIM(email)) AS email,
    INITCAP(TRIM(city)) AS city,
    UPPER(TRIM(country)) AS country,
    TRIM(segment) AS customer_segment,
    TRY_TO_DATE(signup_date) AS signup_date,
    TRY_TO_BOOLEAN(marketing_opt_in) AS marketing_opt_in,
    REGEXP_LIKE(LOWER(TRIM(email)), '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$', 'i') AS is_valid_email,
    loaded_at,
    source_file
FROM RAW.CUSTOMERS_RAW
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIM(customer_id)
    ORDER BY loaded_at DESC, source_file DESC
) = 1;

CREATE OR REPLACE VIEW STAGING.STG_PRODUCTS AS
SELECT
    TRIM(product_id) AS product_id,
    UPPER(TRIM(sku)) AS sku,
    TRIM(product_name) AS product_name,
    TRIM(category) AS category,
    TRIM(brand) AS brand,
    TRY_TO_DECIMAL(unit_price, 10, 2) AS unit_price,
    TRY_TO_BOOLEAN(active_flag) AS active_flag,
    loaded_at,
    source_file
FROM RAW.PRODUCTS_RAW
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIM(product_id)
    ORDER BY loaded_at DESC, source_file DESC
) = 1;

CREATE OR REPLACE VIEW STAGING.STG_ORDERS AS
SELECT
    TRIM(order_id) AS order_id,
    TRIM(customer_id) AS customer_id,
    TRY_TO_DATE(order_date) AS order_date,
    LOWER(TRIM(status)) AS status,
    LOWER(TRIM(payment_method)) AS payment_method,
    INITCAP(TRIM(shipping_city)) AS shipping_city,
    COALESCE(TRY_TO_DECIMAL(discount_amount, 10, 2), 0) AS discount_amount,
    loaded_at,
    source_file
FROM RAW.ORDERS_RAW
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIM(order_id)
    ORDER BY loaded_at DESC, source_file DESC
) = 1;

CREATE OR REPLACE VIEW STAGING.STG_ORDER_ITEMS AS
SELECT
    TRIM(order_item_id) AS order_item_id,
    TRIM(order_id) AS order_id,
    TRIM(product_id) AS product_id,
    TRY_TO_NUMBER(quantity) AS quantity,
    TRY_TO_DECIMAL(unit_price, 10, 2) AS unit_price,
    TRY_TO_NUMBER(quantity) * TRY_TO_DECIMAL(unit_price, 10, 2) AS gross_item_amount,
    loaded_at,
    source_file
FROM RAW.ORDER_ITEMS_RAW
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIM(order_item_id)
    ORDER BY loaded_at DESC, source_file DESC
) = 1;

SELECT 'stg_customers' AS model_name, COUNT(*) AS row_count FROM STAGING.STG_CUSTOMERS
UNION ALL
SELECT 'stg_products', COUNT(*) FROM STAGING.STG_PRODUCTS
UNION ALL
SELECT 'stg_orders', COUNT(*) FROM STAGING.STG_ORDERS
UNION ALL
SELECT 'stg_order_items', COUNT(*) FROM STAGING.STG_ORDER_ITEMS
ORDER BY model_name;

-- Task:
-- Find one cast, one naming cleanup, one deduplication rule, and one validation flag.
--
-- Checkpoint question:
-- Why do we use TRY_TO_DATE and TRY_TO_DECIMAL instead of TO_DATE and TO_DECIMAL in a learning pipeline?

