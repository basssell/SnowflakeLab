-- Hour 1: account setup, role, warehouse, and cost safety.
--
-- Run this script as ACCOUNTADMIN in a Snowflake free trial account.
-- It creates a small learning role and a credit-safe X-SMALL warehouse.

USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS RETAIL_LAB_DEVELOPER
    COMMENT = 'Learning role for the Snowflake 8-hour retail lab';

-- Give the role to the user currently running the script.
SET LAB_USER = CURRENT_USER();
GRANT ROLE RETAIL_LAB_DEVELOPER TO USER IDENTIFIER($LAB_USER);

-- Allow the learning role to create its own lab database and inspect usage.
GRANT CREATE DATABASE ON ACCOUNT TO ROLE RETAIL_LAB_DEVELOPER;
GRANT MONITOR USAGE ON ACCOUNT TO ROLE RETAIL_LAB_DEVELOPER;

-- Needed for the task exercise in sql/09_streams_tasks.sql.
GRANT EXECUTE TASK ON ACCOUNT TO ROLE RETAIL_LAB_DEVELOPER;
GRANT MONITOR EXECUTION ON ACCOUNT TO ROLE RETAIL_LAB_DEVELOPER;

CREATE WAREHOUSE IF NOT EXISTS RETAIL_LAB_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'X-SMALL warehouse for the 8-hour Snowflake retail lab';

-- If the warehouse already existed, make sure it still matches the lab rules.
ALTER WAREHOUSE RETAIL_LAB_WH SET
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

GRANT USAGE, OPERATE, MONITOR ON WAREHOUSE RETAIL_LAB_WH TO ROLE RETAIL_LAB_DEVELOPER;

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;

SELECT
    CURRENT_USER() AS current_user_name,
    CURRENT_ROLE() AS current_role_name,
    CURRENT_WAREHOUSE() AS current_warehouse_name;

-- Cost safety habit:
-- Run this whenever you pause the lab.
-- ALTER WAREHOUSE RETAIL_LAB_WH SUSPEND;

-- Task:
-- Explain why a warehouse is compute, while a database is storage/organization.
--
-- Checkpoint question:
-- Why is AUTO_SUSPEND = 60 important in a free trial account?

