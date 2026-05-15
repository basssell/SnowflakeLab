-- Hour 7: semi-structured JSON with VARIANT, dot notation, and FLATTEN.
--
-- VARIANT stores JSON in Snowflake.
-- Dot notation extracts fields.
-- FLATTEN turns an array inside a JSON document into relational rows.

USE ROLE RETAIL_LAB_DEVELOPER;
USE WAREHOUSE RETAIL_LAB_WH;
USE DATABASE RETAIL_LAB_DB;

CREATE OR REPLACE VIEW STAGING.STG_EVENTS AS
SELECT
    event_payload:event_id::STRING AS event_id,
    TRY_TO_TIMESTAMP_NTZ(event_payload:event_timestamp::STRING) AS event_timestamp,
    event_payload:customer_id::STRING AS customer_id,
    event_payload:session_id::STRING AS session_id,
    event_payload:event_type::STRING AS event_type,
    event_payload:page::STRING AS page,
    event_payload:product_id::STRING AS product_id,
    event_payload:order_id::STRING AS order_id,
    event_payload:device::STRING AS device,
    event_payload:context:utm_source::STRING AS utm_source,
    event_payload:context:campaign::STRING AS campaign,
    event_payload AS raw_event_payload,
    loaded_at,
    source_file
FROM RAW.EVENTS_RAW;

CREATE OR REPLACE VIEW STAGING.STG_EVENT_ITEMS AS
SELECT
    e.event_payload:event_id::STRING AS event_id,
    e.event_payload:customer_id::STRING AS customer_id,
    e.event_payload:event_type::STRING AS event_type,
    flattened_item.index AS item_index,
    flattened_item.value:product_id::STRING AS product_id,
    TRY_TO_NUMBER(flattened_item.value:quantity) AS quantity,
    TRY_TO_DECIMAL(flattened_item.value:unit_price, 10, 2) AS unit_price
FROM RAW.EVENTS_RAW e,
LATERAL FLATTEN(INPUT => e.event_payload:items) flattened_item;

CREATE OR REPLACE VIEW MARTS.V_CUSTOMER_BEHAVIOR_ENRICHED AS
SELECT
    c.customer_id,
    c.customer_segment,
    c.city,
    COUNT(e.event_id) AS total_events,
    COUNT_IF(e.event_type = 'product_view') AS product_views,
    COUNT_IF(e.event_type = 'add_to_cart') AS add_to_cart_events,
    COUNT_IF(e.event_type = 'purchase') AS purchase_events,
    COUNT(DISTINCT e.session_id) AS sessions,
    MIN(e.event_timestamp) AS first_event_at,
    MAX(e.event_timestamp) AS last_event_at
FROM MARTS.DIM_CUSTOMERS c
LEFT JOIN STAGING.STG_EVENTS e
    ON c.customer_id = e.customer_id
GROUP BY c.customer_id, c.customer_segment, c.city;

-- Explore JSON shape.
SELECT event_payload FROM RAW.EVENTS_RAW LIMIT 5;

-- Extract normal columns from VARIANT.
SELECT
    event_id,
    event_timestamp,
    customer_id,
    event_type,
    device,
    utm_source,
    campaign
FROM STAGING.STG_EVENTS
ORDER BY event_timestamp
LIMIT 20;

-- Flatten nested event items.
SELECT *
FROM STAGING.STG_EVENT_ITEMS
ORDER BY event_id, item_index
LIMIT 20;

-- Behavior joined to revenue.
SELECT
    b.customer_segment,
    COUNT(*) AS customers,
    SUM(b.product_views) AS product_views,
    SUM(b.add_to_cart_events) AS add_to_cart_events,
    SUM(b.purchase_events) AS purchase_events,
    SUM(f.net_order_amount) AS known_order_revenue
FROM MARTS.V_CUSTOMER_BEHAVIOR_ENRICHED b
LEFT JOIN MARTS.FACT_ORDERS f
    ON b.customer_id = f.customer_id
    AND f.status NOT IN ('cancelled', 'returned')
GROUP BY b.customer_segment
ORDER BY known_order_revenue DESC;

-- Task:
-- Pick one JSON event and manually identify fields that became columns in STG_EVENTS.
--
-- Checkpoint question:
-- Why does FLATTEN create more rows than the original events table?

