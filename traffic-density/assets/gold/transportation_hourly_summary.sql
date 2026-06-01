/* @bruin
name: gold.transportation_hourly_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

tags:
  - gold

depends:
  - silver.hourly_transportation

@bruin */

SELECT
  SAFE_CAST(date_time AS DATE) AS transportation_date,
  SAFE_CAST(transport_type_id AS INT64) AS transportation_hour,
  SUM(SAFE_CAST(number_of_passenger AS INT64)) AS total_number_of_passengers
FROM silver.hourly_transportation
WHERE date_time IS NOT NULL
  AND transport_type_id IS NOT NULL
  AND number_of_passenger IS NOT NULL
  AND SAFE_CAST(number_of_passenger AS INT64) >= 0
GROUP BY
  transportation_date,
  transportation_hour;