-- Hour 2: raw tables.
--
-- Raw tables keep the source shape close to the files.
-- Most columns are strings here, because typing and business rules happen in STAGING.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

CREATE OR REPLACE TABLE RAW.CUSTOMERS_RAW (
    customer_id STRING,
    first_name STRING,
    last_name STRING,
    email STRING,
    city STRING,
    country STRING,
    segment STRING,
    signup_date STRING,
    marketing_opt_in STRING,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING
);

CREATE OR REPLACE TABLE RAW.PRODUCTS_RAW (
    product_id STRING,
    sku STRING,
    product_name STRING,
    category STRING,
    brand STRING,
    unit_price STRING,
    active_flag STRING,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING
);

CREATE OR REPLACE TABLE RAW.ORDERS_RAW (
    order_id STRING,
    customer_id STRING,
    order_date STRING,
    status STRING,
    payment_method STRING,
    shipping_city STRING,
    discount_amount STRING,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING
);

CREATE OR REPLACE TABLE RAW.ORDER_ITEMS_RAW (
    order_item_id STRING,
    order_id STRING,
    product_id STRING,
    quantity STRING,
    unit_price STRING,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING
);

CREATE OR REPLACE TABLE RAW.EVENTS_RAW (
    event_payload VARIANT,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file STRING
);

SHOW TABLES IN SCHEMA RAW;

-- Task:
-- Inspect each table definition and identify which columns are technical metadata.
--
-- Checkpoint question:
-- Why is event_payload stored as VARIANT instead of flattening every JSON field immediately?

