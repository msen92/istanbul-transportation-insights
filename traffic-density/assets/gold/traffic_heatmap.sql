/* @bruin
name: gold.traffic_heatmap
type: bq.sql

materialization:
  type: table
  strategy: create+replace

tags:
  - gold

depends:
   - silver.traffic_density

@bruin */

WITH cleaned AS (
  SELECT
    SAFE_CAST(DATE_TIME AS TIMESTAMP) AS traffic_timestamp,
    SAFE_CAST(AVERAGE_SPEED AS FLOAT64) AS average_speed,
    SAFE_CAST(NUMBER_OF_VEHICLES AS INT64) AS number_of_vehicles
  FROM `silver.traffic_density`
  WHERE DATE_TIME IS NOT NULL
),

base AS (
  SELECT
    DATE(traffic_timestamp) AS traffic_date,
    FORMAT_DATE('%A', DATE(traffic_timestamp)) AS weekday_name,
    EXTRACT(DAYOFWEEK FROM DATE(traffic_timestamp)) AS weekday_order,
    EXTRACT(HOUR FROM traffic_timestamp) AS traffic_hour,
    AVG(average_speed) AS avg_speed,
    SUM(number_of_vehicles) AS total_vehicles
  FROM cleaned
  WHERE traffic_timestamp IS NOT NULL
    AND average_speed IS NOT NULL
    AND number_of_vehicles IS NOT NULL
  GROUP BY
    traffic_date,
    weekday_name,
    weekday_order,
    traffic_hour
)

SELECT
  weekday_order,
  weekday_name,
  traffic_hour,
  ROUND(avg_speed, 2) AS avg_speed,
  total_vehicles
FROM base;