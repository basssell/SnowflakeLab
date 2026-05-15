-- Hour 8: basic data quality checks.
--
-- Data quality checks make hidden problems visible.
-- They do not need to be fancy: start with business keys, referential checks, and impossible values.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

CREATE OR REPLACE VIEW MARTS.V_ORDER_DATA_QUALITY_ISSUES AS
SELECT
    o.order_id,
    'MISSING_CUSTOMER' AS issue_type,
    'Order customer_id does not exist in dim_customers' AS issue_description,
    'HIGH' AS severity
FROM STAGING.STG_ORDERS o
LEFT JOIN MARTS.DIM_CUSTOMERS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    o.order_id,
    'ORDER_WITH_NO_ITEMS' AS issue_type,
    'Order has no order item rows' AS issue_description,
    'HIGH' AS severity
FROM STAGING.STG_ORDERS o
LEFT JOIN STAGING.STG_ORDER_ITEMS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL

UNION ALL

SELECT
    oi.order_id,
    'INVALID_PRODUCT' AS issue_type,
    'Order item product_id does not exist in dim_products' AS issue_description,
    'MEDIUM' AS severity
FROM STAGING.STG_ORDER_ITEMS oi
LEFT JOIN MARTS.DIM_PRODUCTS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    oi.order_id,
    'INVALID_ITEM_AMOUNT' AS issue_type,
    'Order item has zero/negative quantity or price' AS issue_description,
    'MEDIUM' AS severity
FROM STAGING.STG_ORDER_ITEMS oi
WHERE COALESCE(oi.quantity, 0) <= 0
   OR COALESCE(oi.unit_price, 0) <= 0

UNION ALL

SELECT
    f.order_id,
    'DISCOUNT_EXCEEDS_GROSS_AMOUNT' AS issue_type,
    'Discount is greater than gross order amount' AS issue_description,
    'MEDIUM' AS severity
FROM MARTS.FACT_ORDERS f
WHERE f.discount_amount > f.gross_order_amount;

CREATE OR REPLACE VIEW MARTS.V_CUSTOMER_DATA_QUALITY_ISSUES AS
SELECT
    customer_id,
    'INVALID_EMAIL' AS issue_type,
    'Email does not match a basic email pattern' AS issue_description,
    'LOW' AS severity
FROM MARTS.DIM_CUSTOMERS
WHERE NOT is_valid_email;

CREATE OR REPLACE VIEW MARTS.V_DATA_QUALITY_SUMMARY AS
SELECT
    'orders' AS object_checked,
    issue_type,
    severity,
    COUNT(*) AS issue_count
FROM MARTS.V_ORDER_DATA_QUALITY_ISSUES
GROUP BY issue_type, severity

UNION ALL

SELECT
    'customers' AS object_checked,
    issue_type,
    severity,
    COUNT(*) AS issue_count
FROM MARTS.V_CUSTOMER_DATA_QUALITY_ISSUES
GROUP BY issue_type, severity;

SELECT *
FROM MARTS.V_DATA_QUALITY_SUMMARY
ORDER BY object_checked, severity, issue_type;

SELECT *
FROM MARTS.V_ORDER_DATA_QUALITY_ISSUES
ORDER BY severity, issue_type, order_id;

-- Task:
-- Pick one issue type and trace it back from MARTS to STAGING to RAW.
--
-- Checkpoint question:
-- Why should data quality checks return rows that humans can investigate, not just TRUE/FALSE?

