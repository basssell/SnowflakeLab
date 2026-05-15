-- Hour 3: PUT local files into internal stages, then COPY INTO raw tables.
--
-- Important:
-- PUT reads files from your local machine. Snowsight worksheets cannot access your local filesystem.
-- Run the PUT commands with SnowSQL or Snowflake CLI from the repository root.
-- If relative paths fail on Windows, replace file://data/generated/... with an absolute path like:
-- file://C:/Users/your_name/path/to/snowflake-8h-lab/data/generated/customers.csv

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

-- 1) Upload files to Snowflake internal stages.
PUT file://data/generated/customers.csv @RAW.CSV_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
PUT file://data/generated/products.csv @RAW.CSV_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
PUT file://data/generated/orders.csv @RAW.CSV_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
PUT file://data/generated/order_items.csv @RAW.CSV_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
PUT file://data/generated/events.json @RAW.JSON_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;

LIST @RAW.CSV_STAGE;
LIST @RAW.JSON_STAGE;

-- 2) Keep this lab repeatable: clear raw tables before the initial full load.
TRUNCATE TABLE RAW.CUSTOMERS_RAW;
TRUNCATE TABLE RAW.PRODUCTS_RAW;
TRUNCATE TABLE RAW.ORDERS_RAW;
TRUNCATE TABLE RAW.ORDER_ITEMS_RAW;
TRUNCATE TABLE RAW.EVENTS_RAW;

-- 3) Load CSV files.
COPY INTO RAW.CUSTOMERS_RAW (
    customer_id,
    first_name,
    last_name,
    email,
    city,
    country,
    segment,
    signup_date,
    marketing_opt_in,
    source_file
)
FROM (
    SELECT
        $1::STRING,
        $2::STRING,
        $3::STRING,
        $4::STRING,
        $5::STRING,
        $6::STRING,
        $7::STRING,
        $8::STRING,
        $9::STRING,
        METADATA$FILENAME::STRING
    FROM @RAW.CSV_STAGE/customers.csv
)
FILE_FORMAT = (FORMAT_NAME = UTIL.CSV_STANDARD)
ON_ERROR = ABORT_STATEMENT;

COPY INTO RAW.PRODUCTS_RAW (
    product_id,
    sku,
    product_name,
    category,
    brand,
    unit_price,
    active_flag,
    source_file
)
FROM (
    SELECT
        $1::STRING,
        $2::STRING,
        $3::STRING,
        $4::STRING,
        $5::STRING,
        $6::STRING,
        $7::STRING,
        METADATA$FILENAME::STRING
    FROM @RAW.CSV_STAGE/products.csv
)
FILE_FORMAT = (FORMAT_NAME = UTIL.CSV_STANDARD)
ON_ERROR = ABORT_STATEMENT;

COPY INTO RAW.ORDERS_RAW (
    order_id,
    customer_id,
    order_date,
    status,
    payment_method,
    shipping_city,
    discount_amount,
    source_file
)
FROM (
    SELECT
        $1::STRING,
        $2::STRING,
        $3::STRING,
        $4::STRING,
        $5::STRING,
        $6::STRING,
        $7::STRING,
        METADATA$FILENAME::STRING
    FROM @RAW.CSV_STAGE/orders.csv
)
FILE_FORMAT = (FORMAT_NAME = UTIL.CSV_STANDARD)
ON_ERROR = ABORT_STATEMENT;

COPY INTO RAW.ORDER_ITEMS_RAW (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    source_file
)
FROM (
    SELECT
        $1::STRING,
        $2::STRING,
        $3::STRING,
        $4::STRING,
        $5::STRING,
        METADATA$FILENAME::STRING
    FROM @RAW.CSV_STAGE/order_items.csv
)
FILE_FORMAT = (FORMAT_NAME = UTIL.CSV_STANDARD)
ON_ERROR = ABORT_STATEMENT;

-- 4) Load JSON Lines. Each line becomes one VARIANT row.
COPY INTO RAW.EVENTS_RAW (
    event_payload,
    source_file
)
FROM (
    SELECT
        $1,
        METADATA$FILENAME::STRING
    FROM @RAW.JSON_STAGE/events.json
)
FILE_FORMAT = (FORMAT_NAME = UTIL.JSON_EVENTS)
ON_ERROR = ABORT_STATEMENT;

-- 5) Validate row counts.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM RAW.CUSTOMERS_RAW
UNION ALL
SELECT 'products', COUNT(*) FROM RAW.PRODUCTS_RAW
UNION ALL
SELECT 'orders', COUNT(*) FROM RAW.ORDERS_RAW
UNION ALL
SELECT 'order_items', COUNT(*) FROM RAW.ORDER_ITEMS_RAW
UNION ALL
SELECT 'events', COUNT(*) FROM RAW.EVENTS_RAW
ORDER BY table_name;

-- Task:
-- Compare LIST output with the COPY row counts. Files in a stage are not the same as rows in a table.
--
-- Checkpoint question:
-- What is the difference between PUT and COPY INTO?

