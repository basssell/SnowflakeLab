# Snowflake 8-Hour Retail Analytics Lab

This is a practical Snowflake fundamentals project for a junior Data Engineer or Analytics Engineer portfolio. You will build a small analytics warehouse for an e-commerce dataset using only a Snowflake free trial, local CSV/JSON files, SQL scripts, and an X-SMALL warehouse.

The goal is not to build a production platform. The goal is to understand Snowflake objects deeply enough that you can explain them in interviews and use them with confidence.

## What You Will Build

You will generate local retail data, upload it into Snowflake internal stages, load raw tables, transform the data into staging views, create analytics marts, analyze KPIs, parse JSON events, practice Time Travel and zero-copy cloning, run a small stream/task incremental exercise, and finish with data quality and cost monitoring queries.

Business questions answered by the end:

- What is the revenue by day?
- What are the top products by revenue?
- What are the best customer segments?
- What is the average order value?
- Which orders have data quality issues?
- How do JSON events enrich customer behavior?
- What changed after an incremental load?

## Repository Structure

```text
snowflake-8h-lab/
  README.md
  .env.example
  data/
    raw/
    generated/
  scripts/
    generate_data.py
  sql/
    00_setup_roles_warehouse.sql
    01_create_database_schemas.sql
    02_create_file_formats_stages.sql
    03_create_raw_tables.sql
    04_load_data.sql
    05_create_staging_models.sql
    06_create_marts.sql
    07_semi_structured_json.sql
    08_time_travel_clone.sql
    09_streams_tasks.sql
    10_data_quality_checks.sql
    11_cost_monitoring_queries.sql
  docs/
    architecture.md
    learning_notes.md
    interview_explanation.md
```

## Cost Safety Rules

Use these habits every time:

- Use only `RETAIL_LAB_WH`.
- Keep it `XSMALL`.
- Keep `AUTO_SUSPEND = 60`.
- Keep `AUTO_RESUME = TRUE`.
- Suspend the warehouse whenever you take a break:

```sql
ALTER WAREHOUSE RETAIL_LAB_WH SUSPEND;
```

This lab uses tiny files and simple SQL. It is designed for a free trial, but you are still responsible for watching credit usage.

## Snowflake Object Cheat Sheet

- Role: who is allowed to do something.
- Warehouse: compute that runs SQL and loads data.
- Database: top-level storage and organization container.
- Schema: folder-like grouping inside a database.
- Table: stored rows and columns.
- View: saved SQL query.
- File format: parsing rules for files, such as CSV headers or JSON.
- Stage: Snowflake location where files sit before loading.
- Task: scheduled or manually executed SQL.
- Stream: change tracker for a table.

## Prerequisites

You need:

- A Snowflake free trial account.
- Access to Snowsight.
- Local Python 3.10 or newer to generate the files.
- SnowSQL or Snowflake CLI for `PUT` commands, because Snowsight cannot upload files from your local filesystem with `PUT`.

No paid external cloud storage is required.

## Step 0: Generate Local Data

From this repository:

```powershell
python .\scripts\generate_data.py
```

Expected generated files:

- `data/generated/customers.csv`: 100 rows
- `data/generated/products.csv`: 50 rows
- `data/generated/orders.csv`: 500 rows
- `data/generated/order_items.csv`: 1,200 rows
- `data/generated/events.json`: 500 JSON lines
- `data/generated/orders_incremental.csv`: 20 rows for Hour 7
- `data/generated/order_items_incremental.csv`: 50 rows for Hour 7

The dataset intentionally contains a few realistic issues: missing customer references, invalid product references, orders without items, high discounts, zero quantities, and one invalid email.

## How To Run The SQL

Follow the hour plan below. Scripts `02_create_file_formats_stages.sql` and `03_create_raw_tables.sql` are independent; both simply need to run before `04_load_data.sql`.

For `00`, use the `ACCOUNTADMIN` role in Snowsight.

For most other scripts, use the `RETAIL_LAB_DEVELOPER` role created by `00`.

Important: scripts `04_load_data.sql` and `09_streams_tasks.sql` contain `PUT` commands. Run those `PUT` statements with SnowSQL or Snowflake CLI from the repository root. If relative paths fail on Windows, replace them with absolute paths such as:

```sql
PUT file://C:/Users/your_name/path/to/snowflake-8h-lab/data/generated/customers.csv @RAW.CSV_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
```

After the files are staged, you can run the `COPY INTO` statements in Snowsight.

## 8-Hour Plan

### Hour 1: Environment, Warehouse, Database, Schemas

Explain simply:

Snowflake separates compute from storage. The warehouse runs work. The database stores and organizes objects. Roles control access.

Run:

- `sql/00_setup_roles_warehouse.sql`
- `sql/01_create_database_schemas.sql`

Task:

Write one sentence for each object: role, warehouse, database, schema.

Checkpoint question:

Why can the warehouse be suspended without deleting your tables?

### Hour 2: Generate Data And Create Raw Tables

Explain simply:

Raw tables are the landing zone. They keep source data close to the file shape so you can debug loading problems.

Run locally:

```powershell
python .\scripts\generate_data.py
```

Run in Snowflake:

- `sql/03_create_raw_tables.sql`

Task:

Open each generated file and compare its columns with the raw table definition.

Checkpoint question:

Why are many raw columns strings instead of final data types?

### Hour 3: File Formats, Stages, PUT, COPY INTO

Explain simply:

A stage stores files. A file format tells Snowflake how to read them. `PUT` uploads local files. `COPY INTO` loads staged files into tables.

Run:

- `sql/02_create_file_formats_stages.sql`
- `sql/04_load_data.sql`

Task:

Use `LIST @RAW.CSV_STAGE;` and row counts to prove files and table rows are different things.

Checkpoint question:

What problem does `FILE_FORMAT = UTIL.CSV_STANDARD` solve?

### Hour 4: Staging Transformations

Explain simply:

Staging is where raw strings become typed, cleaned, consistently named columns.

Run:

- `sql/05_create_staging_models.sql`

Task:

Find the SQL line that casts `order_date`, the line that validates email, and the line that deduplicates customers.

Checkpoint question:

Why is `TRY_TO_DATE` safer than `TO_DATE` during early pipeline development?

### Hour 5: Marts

Explain simply:

Marts are built for business questions. Dimensions describe entities. Facts store measurable events.

Run:

- `sql/06_create_marts.sql`

Task:

Trace `net_order_amount` from raw order items to the final fact table.

Checkpoint question:

Why is `FACT_ORDERS` useful for KPIs while `FACT_ORDER_ITEMS` is useful for product analysis?

### Hour 6: Analytical SQL

Explain simply:

Views let you save useful business questions as reusable SQL. Window functions help analyze rankings and trends.

Run again and study:

- KPI views in `sql/06_create_marts.sql`

Task:

Answer these questions in Snowflake:

- Revenue by day
- Top 10 products by revenue
- Segment revenue and average order value
- Running revenue over time

Checkpoint question:

What does `RANK() OVER (ORDER BY revenue DESC)` do that a normal `ORDER BY` does not?

### Hour 7: Snowflake-Specific Features

Explain simply:

Snowflake can query JSON directly, recover old data using Time Travel, clone objects quickly, and track incremental table changes with streams.

Run:

- `sql/07_semi_structured_json.sql`
- `sql/08_time_travel_clone.sql`
- `sql/09_streams_tasks.sql`

Task:

After the incremental load, rerun `sql/06_create_marts.sql` and compare order counts before and after.

Checkpoint question:

Why should you suspend the task immediately after the exercise?

### Hour 8: Data Quality, Cost Monitoring, Documentation

Explain simply:

A portfolio project is stronger when it shows you know how to validate data and control cost, not just write happy-path transformations.

Run:

- `sql/10_data_quality_checks.sql`
- `sql/11_cost_monitoring_queries.sql`

Task:

Pick three data quality issues and explain their business impact.

Checkpoint question:

Which query in your history scanned the most bytes, and why?

## Troubleshooting

`SQL access control error`

You are probably using the wrong role. Run:

```sql
USE ROLE RETAIL_LAB_DEVELOPER;
```

If `00_setup_roles_warehouse.sql` failed, rerun it as `ACCOUNTADMIN`.

`Warehouse is suspended`

This is normal. With `AUTO_RESUME = TRUE`, Snowflake resumes it when a query needs compute. You can also run:

```sql
ALTER WAREHOUSE RETAIL_LAB_WH RESUME;
```

`PUT is not supported in this context`

You are likely running `PUT` in Snowsight. Use SnowSQL or Snowflake CLI locally.

`File not found during PUT`

Use an absolute path with forward slashes:

```sql
PUT file://C:/Users/your_name/path/to/snowflake-8h-lab/data/generated/orders.csv @RAW.CSV_STAGE AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
```

`COPY INTO loaded 0 rows`

Check:

```sql
LIST @RAW.CSV_STAGE;
```

Then confirm the staged filename matches the path in the `COPY INTO` statement.

`Object does not exist or not authorized`

Confirm role, database, and warehouse:

```sql
SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_WAREHOUSE();
```

`Task did not run`

Check task history and make sure the stream has data:

```sql
SELECT COUNT(*) FROM RAW.ORDERS_RAW_STREAM;
```

Tasks also need a resumed state for scheduled execution. Suspend the task again after the exercise.

## How To Explain This Project In An Interview

Short version:

I built a small Snowflake retail analytics warehouse using local CSV and JSON files. I used an X-SMALL warehouse with auto-suspend for cost safety, loaded data through internal stages, created raw/staging/mart layers, parsed semi-structured JSON events with VARIANT and FLATTEN, practiced Time Travel and zero-copy cloning, and used streams/tasks for a small incremental processing exercise. I finished with data quality checks and cost monitoring queries.

For a deeper interview script, see `docs/interview_explanation.md`.
