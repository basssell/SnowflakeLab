-- Hour 8: query history and cost awareness.
--
-- Cost habits matter even in a free trial.
-- Use the smallest warehouse, suspend it when idle, and inspect what your queries scanned.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

-- Recent queries by the current user.
SELECT
    start_time,
    query_type,
    execution_status,
    warehouse_name,
    total_elapsed_time / 1000 AS elapsed_seconds,
    bytes_scanned,
    rows_produced,
    query_text
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY_BY_USER(
    USER_NAME => CURRENT_USER(),
    END_TIME_RANGE_START => DATEADD('hour', -8, CURRENT_TIMESTAMP())
))
WHERE warehouse_name = 'RETAIL_LAB_WH'
ORDER BY start_time DESC
LIMIT 50;

-- Warehouse credit usage. ACCOUNT_USAGE can lag, often by a few hours.
SELECT
    start_time,
    end_time,
    warehouse_name,
    credits_used,
    credits_used_compute,
    credits_used_cloud_services
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE warehouse_name = 'RETAIL_LAB_WH'
  AND start_time >= DATEADD('day', -2, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

-- Current warehouse configuration.
SHOW WAREHOUSES LIKE 'RETAIL_LAB_WH';

-- Final cost safety command.
ALTER WAREHOUSE RETAIL_LAB_WH SUSPEND;

-- Task:
-- Find the longest-running query from this lab and explain why it scanned the data it scanned.
--
-- Checkpoint question:
-- Why is a suspended warehouse not the same thing as deleting your database?

