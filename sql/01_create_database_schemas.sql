-- Hour 1: database and schema layout.
--
-- A database is the top-level container.
-- Schemas group objects by purpose.
-- This lab uses a simple raw -> staging -> marts flow.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;

CREATE DATABASE IF NOT EXISTS RETAIL_LAB_DB
    DATA_RETENTION_TIME_IN_DAYS = 1
    COMMENT = 'Mini analytics warehouse for an e-commerce Snowflake lab';

USE DATABASE RETAIL_LAB_DB;

CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Landing zone for data loaded from local files';

CREATE SCHEMA IF NOT EXISTS STAGING
    COMMENT = 'Cleaned and typed transformation layer';

CREATE SCHEMA IF NOT EXISTS MARTS
    COMMENT = 'Analytics-ready facts, dimensions, and KPI views';

CREATE SCHEMA IF NOT EXISTS UTIL
    COMMENT = 'Shared technical objects such as file formats, tasks, and helper objects';

SHOW SCHEMAS IN DATABASE RETAIL_LAB_DB;

-- Task:
-- Draw the flow: local files -> internal stage -> RAW tables -> STAGING views -> MARTS tables/views.
--
-- Checkpoint question:
-- Why do we separate RAW, STAGING, and MARTS instead of loading directly into final analytics tables?

