# Learning Notes

Use this as your active worksheet. After each hour, write your own answers under the checkpoint questions.

## Hour 1: Environment Setup

Simple explanation:

Snowflake has storage, compute, and permissions as separate concepts. The role decides what you can do. The warehouse provides compute. The database and schemas organize stored objects.

SQL to run:

- `sql/00_setup_roles_warehouse.sql`
- `sql/01_create_database_schemas.sql`

Task:

Write definitions in your own words:

- Role:
- Warehouse:
- Database:
- Schema:

Checkpoint:

- Why does using `ACCOUNTADMIN` for everything make a project less realistic?
- Why is `AUTO_SUSPEND = 60` useful?
- What does `AUTO_RESUME = TRUE` change about the user experience?

## Hour 2: Local Data And Raw Tables

Simple explanation:

Raw tables are your evidence layer. If something goes wrong later, you can return to raw data and check whether the issue came from the file or from your transformation.

SQL and commands:

- `python .\scripts\generate_data.py`
- `sql/03_create_raw_tables.sql`

Task:

Open each file in `data/generated/` and compare the header to the raw table.

Checkpoint:

- Why are raw values often strings?
- Why do raw tables include `loaded_at` and `source_file`?
- What kind of debugging question can raw data answer?

## Hour 3: File Loading

Simple explanation:

Files do not jump directly from your laptop into tables. First, `PUT` uploads them to an internal stage. Then `COPY INTO` reads the staged files and inserts rows into raw tables.

SQL to run:

- `sql/02_create_file_formats_stages.sql`
- `sql/04_load_data.sql`

Task:

Run `LIST @RAW.CSV_STAGE;` and compare it with raw table row counts.

Checkpoint:

- What is the stage responsible for?
- What is the file format responsible for?
- What does `ON_ERROR = ABORT_STATEMENT` protect you from?

## Hour 4: Staging Models

Simple explanation:

Staging is a translation layer. It turns messy source-shaped data into clean warehouse-shaped data.

SQL to run:

- `sql/05_create_staging_models.sql`

Task:

Identify these in the SQL:

- A column rename
- A type cast
- A deduplication rule
- A validation flag

Checkpoint:

- Why are staging views useful during development?
- What does `QUALIFY ROW_NUMBER()` do?
- Why should casting happen before building marts?

## Hour 5: Marts

Simple explanation:

Marts are designed around questions. Facts are measurable events. Dimensions describe the people, products, or other business entities involved.

SQL to run:

- `sql/06_create_marts.sql`

Task:

Trace these fields:

- `customer_segment`
- `gross_item_amount`
- `net_order_amount`

Checkpoint:

- Why is `FACT_ORDER_ITEMS` more detailed than `FACT_ORDERS`?
- Which table would you use for top products?
- Which table would you use for average order value?

## Hour 6: Analytical SQL

Simple explanation:

Analytical SQL turns transformed data into business answers. A portfolio project should show that you can ask and answer practical questions, not only move data.

SQL to study:

- KPI views and example queries in `sql/06_create_marts.sql`

Task:

Answer:

- Revenue by day:
- Top product:
- Best customer segment by revenue:
- Average order value:

Checkpoint:

- What does a window function do?
- Why would a business user care about running revenue?
- Why should cancelled and returned orders usually be excluded from revenue KPIs?

## Hour 7: Snowflake-Specific Features

Simple explanation:

Snowflake has features that are useful in real projects: JSON support, Time Travel, cloning, streams, and tasks. This hour gives you enough hands-on exposure to explain them without pretending to be an expert in advanced orchestration.

SQL to run:

- `sql/07_semi_structured_json.sql`
- `sql/08_time_travel_clone.sql`
- `sql/09_streams_tasks.sql`

Task:

Use `STAGING.STG_EVENTS` and `STAGING.STG_EVENT_ITEMS` to explain how nested JSON becomes relational.

Checkpoint:

- Why is `VARIANT` useful?
- What does `FLATTEN` do?
- What is the difference between Time Travel and a clone?
- What does a stream remember?
- Why are tasks a cost risk if you forget about them?

## Hour 8: Quality, Cost, And Interview Story

Simple explanation:

The final hour makes the project credible. You show that you can check data quality, inspect query history, think about cost, and explain tradeoffs.

SQL to run:

- `sql/10_data_quality_checks.sql`
- `sql/11_cost_monitoring_queries.sql`

Task:

Pick three data quality issues and write:

- What is wrong?
- How did the SQL detect it?
- What business decision could it affect?

Checkpoint:

- Which data quality check found the most issues?
- Which query scanned the most bytes?
- When exactly should you suspend the warehouse?
- How would you explain this project in two minutes?

