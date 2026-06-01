/* @bruin
name: gold.transportation_town_mode_summary
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
  UPPER(TRIM(CAST(town AS STRING))) AS town,
  UPPER(TRIM(CAST(road_type AS STRING))) AS road_type,
  SUM(SAFE_CAST(number_of_passenger AS INT64)) AS total_passengers
FROM silver.hourly_transportation
WHERE town IS NOT NULL
  AND TRIM(CAST(town AS STRING)) != ''
  AND road_type IS NOT NULL
  AND number_of_passenger IS NOT NULL
  AND SAFE_CAST(number_of_passenger AS INT64) >= 0
GROUP BY
  town,
  road_type;