/* @bruin
name: gold.transportation_daily_road_summary
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

  SUM(SAFE_CAST(number_of_passenger AS INT64)) AS total_road_passengers

FROM silver.hourly_transportation
WHERE date_time IS NOT NULL
  AND number_of_passenger IS NOT NULL
  AND SAFE_CAST(number_of_passenger AS INT64) >= 0
  AND UPPER(TRIM(road_type)) = 'OTOYOL'
GROUP BY
  transportation_date;