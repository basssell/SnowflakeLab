-- Hour 7: streams and tasks for incremental processing.
--
-- A stream records changes made to a table after the stream is created.
-- A task runs SQL on a schedule or by manual execution.
-- To protect trial credits, keep this task suspended except during the exercise.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

-- 1) Create a stream before loading incremental orders.
CREATE OR REPLACE STREAM RAW.ORDERS_RAW_STREAM
    ON TABLE RAW.ORDERS_RAW
    APPEND_ONLY = TRUE;

CREATE OR REPLACE TABLE MARTS.ORDER_INCREMENT_AUDIT (
    processed_at TIMESTAMP_NTZ,
    order_id STRING,
    customer_id STRING,
    order_date DATE,
    status STRING,
    net_order_amount NUMBER(12, 2),
    stream_action STRING,
    stream_is_update BOOLEAN
);

-- 2) Create the task. It starts suspended by default after CREATE TASK.
CREATE OR REPLACE TASK UTIL.LOAD_NEW_ORDERS_AUDIT_TASK
    WAREHOUSE = RETAIL_LAB_WH
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('RAW.ORDERS_RAW_STREAM')
AS
INSERT INTO MARTS.ORDER_INCREMENT_AUDIT (
    processed_at,
    order_id,
    customer_id,
    order_date,
    status,
    net_order_amount,
    stream_action,
    stream_is_update
)
WITH incoming_orders AS (
    SELECT
        s.order_id,
        s.customer_id,
        TRY_TO_DATE(s.order_date) AS order_date,
        LOWER(TRIM(s.status)) AS status,
        COALESCE(TRY_TO_DECIMAL(s.discount_amount, 10, 2), 0) AS discount_amount,
        METADATA$ACTION AS stream_action,
        METADATA$ISUPDATE AS stream_is_update
    FROM RAW.ORDERS_RAW_STREAM s
),
item_rollup AS (
    SELECT
        order_id,
        SUM(COALESCE(gross_item_amount, 0)) AS gross_order_amount
    FROM STAGING.STG_ORDER_ITEMS
    GROUP BY order_id
)
SELECT
    CURRENT_TIMESTAMP(),
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    GREATEST(COALESCE(i.gross_order_amount, 0) - o.discount_amount, 0) AS net_order_amount,
    o.stream_action,
    o.stream_is_update
FROM incoming_orders o
LEFT JOIN item_rollup i
    ON o.order_id = i.order_id;

-- 3) Upload incremental files with SnowSQL or Snowflake CLI from the repository root.
-- Snowsight cannot execute PUT against your local filesystem.
PUT file://data/generated/orders_incremental.csv @RAW.CSV_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
PUT file://data/generated/order_items_incremental.csv @RAW.CSV_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;

-- 4) Load new rows into raw tables. The stream records the new order rows.
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
    FROM @RAW.CSV_STAGE/orders_incremental.csv
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
    FROM @RAW.CSV_STAGE/order_items_incremental.csv
)
FILE_FORMAT = (FORMAT_NAME = UTIL.CSV_STANDARD)
ON_ERROR = ABORT_STATEMENT;

-- 5) Inspect the stream before consuming it.
SELECT
    COUNT(*) AS pending_stream_rows
FROM RAW.ORDERS_RAW_STREAM;

SELECT
    order_id,
    customer_id,
    order_date,
    METADATA$ACTION AS stream_action,
    METADATA$ISUPDATE AS stream_is_update
FROM RAW.ORDERS_RAW_STREAM
ORDER BY order_id
LIMIT 20;

-- 6) Run the task once, then suspend it again for cost safety.
ALTER TASK UTIL.LOAD_NEW_ORDERS_AUDIT_TASK RESUME;
EXECUTE TASK UTIL.LOAD_NEW_ORDERS_AUDIT_TASK;

-- Wait 10-20 seconds in Snowsight, then check whether the task succeeded.
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME => 'LOAD_NEW_ORDERS_AUDIT_TASK',
    RESULT_LIMIT => 10
))
ORDER BY SCHEDULED_TIME DESC;

ALTER TASK UTIL.LOAD_NEW_ORDERS_AUDIT_TASK SUSPEND;

SELECT *
FROM MARTS.ORDER_INCREMENT_AUDIT
ORDER BY processed_at DESC, order_id;

-- 7) Refresh the mart tables after the incremental raw load by rerunning:
-- sql/06_create_marts.sql

-- Task:
-- Compare row counts before and after the incremental load.
--
-- Checkpoint question:
-- Why does reading from a stream consume its pending change records?
