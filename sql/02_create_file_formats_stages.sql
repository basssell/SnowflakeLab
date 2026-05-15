-- Hour 3: file formats and internal stages.
--
-- A file format tells Snowflake how to read a file.
-- A stage is a Snowflake location where files are stored before loading.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

CREATE OR REPLACE FILE FORMAT UTIL.CSV_STANDARD
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('', 'NULL', 'null')
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    COMMENT = 'CSV format for generated retail files with one header row';

CREATE OR REPLACE FILE FORMAT UTIL.JSON_EVENTS
    TYPE = JSON
    STRIP_OUTER_ARRAY = FALSE
    COMMENT = 'JSON Lines format: one event object per line';

CREATE OR REPLACE STAGE RAW.CSV_STAGE
    FILE_FORMAT = UTIL.CSV_STANDARD
    COMMENT = 'Internal stage for generated CSV files';

CREATE OR REPLACE STAGE RAW.JSON_STAGE
    FILE_FORMAT = UTIL.JSON_EVENTS
    COMMENT = 'Internal stage for generated JSON event files';

SHOW FILE FORMATS IN SCHEMA UTIL;
SHOW STAGES IN SCHEMA RAW;

-- Task:
-- Explain why the stage stores files, but the file format only describes how to parse those files.
--
-- Checkpoint question:
-- What would happen if SKIP_HEADER was set to 0 for these CSV files?

