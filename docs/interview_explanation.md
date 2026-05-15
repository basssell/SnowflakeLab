# Interview Explanation

## Two-Minute Project Pitch

I built a mini Snowflake analytics warehouse for a retail dataset using only a free trial and local files. I generated customers, products, orders, order items, and JSON clickstream events locally, uploaded them with internal stages, and loaded them into raw tables with `COPY INTO`.

Then I built a clear raw, staging, and mart architecture. The staging layer handled casting, naming, deduplication, and basic validation. The marts exposed customer and product dimensions, order facts, order item facts, and KPI views for revenue by day, top products, customer segments, and average order value.

I also practiced Snowflake-specific features: JSON parsing with `VARIANT`, nested arrays with `FLATTEN`, Time Travel recovery, zero-copy cloning for safe testing, and a stream/task example for incremental orders. I finished the project with data quality checks and query history/cost monitoring. I used an X-SMALL warehouse with auto-suspend to keep the lab safe for a free trial.

## What This Shows

- I understand the difference between compute, storage, and permissions in Snowflake.
- I can load local CSV and JSON files without external cloud services.
- I can model a simple analytics warehouse with raw, staging, and mart layers.
- I can write analytical SQL for business KPIs.
- I can work with semi-structured JSON data.
- I can explain Snowflake Time Travel, cloning, streams, and tasks at a fundamentals level.
- I care about data quality and cost awareness.

## Architecture Explanation

The pipeline is:

```text
Local files
  -> internal stages
  -> RAW tables
  -> STAGING views
  -> MARTS tables and KPI views
```

I kept raw data close to the source so loading issues are easy to debug. I used staging views to cast and clean data without storing unnecessary copies. I created mart tables where business users would expect stable analytics objects.

## Example Interview Questions And Answers

Question: Why did you use an internal stage?

Answer: The internal stage is the Snowflake-managed location where local files are placed before loading. `PUT` uploads files into the stage, and `COPY INTO` loads from the stage into raw tables. This makes loading explicit and inspectable.

Question: Why did you keep raw columns as strings?

Answer: Raw tables are the landing layer. Keeping values as strings makes it easier to load files and debug source issues. I cast data in staging, where I can use `TRY_TO_DATE` and `TRY_TO_DECIMAL` safely.

Question: What is the difference between a warehouse and a database?

Answer: A warehouse is compute. It runs queries and loads. A database is storage and organization for objects like schemas, tables, and views. Suspending a warehouse stops compute billing but does not delete the data.

Question: What does `FLATTEN` do?

Answer: `FLATTEN` takes an array inside a VARIANT JSON document and returns one row per array element. I used it to turn nested event items into relational rows.

Question: How did you handle incremental data?

Answer: I created a stream on the raw orders table before loading incremental order files. The stream captured inserted rows. Then a task consumed those changes into an audit table. After that I refreshed the mart tables.

Question: What did your data quality checks catch?

Answer: They catch missing customer references, orders with no items, invalid product references, invalid item quantities or prices, discounts greater than gross order amount, and invalid customer emails.

Question: How did you control cost?

Answer: I used one X-SMALL warehouse, set `AUTO_SUSPEND = 60`, enabled `AUTO_RESUME`, kept the dataset small, avoided heavy workloads, and suspended the warehouse and task after use. I also queried query history and warehouse metering history.

## Strong Portfolio Summary

Project name:

Snowflake Retail Analytics Mini Warehouse

One-line summary:

Built a small Snowflake analytics warehouse from local CSV/JSON files with raw/staging/mart modeling, JSON parsing, incremental stream/task processing, data quality checks, and cost monitoring.

Skills demonstrated:

- Snowflake SQL
- Warehouses and cost safety
- Roles and grants
- Internal stages and file formats
- `PUT` and `COPY INTO`
- Raw/staging/mart modeling
- Facts and dimensions
- Analytical SQL and window functions
- JSON `VARIANT` and `FLATTEN`
- Time Travel and zero-copy cloning
- Streams and tasks
- Data quality checks
- Query history and usage monitoring

## Honest Scope Statement

This is an 8-hour fundamentals lab, not a production platform. I did not add dbt, Airflow, external cloud storage, CI/CD, masking policies, or complex orchestration because the goal was to deeply practice Snowflake basics in a controlled free-trial environment.

That honesty is good in interviews. It shows judgment.

