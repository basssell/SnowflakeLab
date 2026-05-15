-- Hour 7: Time Travel and zero-copy cloning.
--
-- Time Travel lets you query a table as it existed before a change.
-- Zero-copy cloning creates a quick copy that shares storage until data changes.
-- This script uses demo objects so your main marts remain safe.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

CREATE OR REPLACE TABLE MARTS.FACT_ORDERS_TIME_TRAVEL_DEMO CLONE MARTS.FACT_ORDERS;

SELECT COUNT(*) AS rows_before_delete
FROM MARTS.FACT_ORDERS_TIME_TRAVEL_DEMO;

DELETE FROM MARTS.FACT_ORDERS_TIME_TRAVEL_DEMO
WHERE status = 'cancelled';

SET DELETE_QUERY_ID = (SELECT LAST_QUERY_ID());

SELECT COUNT(*) AS rows_after_delete
FROM MARTS.FACT_ORDERS_TIME_TRAVEL_DEMO;

SELECT COUNT(*) AS rows_before_delete_using_time_travel
FROM MARTS.FACT_ORDERS_TIME_TRAVEL_DEMO
BEFORE (STATEMENT => $DELETE_QUERY_ID);

CREATE OR REPLACE TABLE MARTS.FACT_ORDERS_RESTORED_DEMO CLONE MARTS.FACT_ORDERS_TIME_TRAVEL_DEMO
BEFORE (STATEMENT => $DELETE_QUERY_ID);

SELECT COUNT(*) AS restored_rows
FROM MARTS.FACT_ORDERS_RESTORED_DEMO;

-- Zero-copy clone a full schema for sandbox analysis.
CREATE OR REPLACE SCHEMA MARTS_CLONE CLONE MARTS;

SELECT COUNT(*) AS cloned_fact_orders
FROM MARTS_CLONE.FACT_ORDERS;

-- Clean up demo clone schema when finished.
DROP SCHEMA IF EXISTS MARTS_CLONE;

-- Keep the restored demo tables so you can inspect them, or drop them after practice:
-- DROP TABLE IF EXISTS MARTS.FACT_ORDERS_TIME_TRAVEL_DEMO;
-- DROP TABLE IF EXISTS MARTS.FACT_ORDERS_RESTORED_DEMO;

-- Task:
-- Explain the difference between restoring from Time Travel and cloning a table.
--
-- Checkpoint question:
-- Why is zero-copy cloning useful for testing changes without duplicating all data immediately?

