/* @bruin
name: gold.traffic_daily_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

tags:
  - gold

depends:
  - silver.traffic_density

@bruin */

SELECT
  DATE_TIME,

  SAFE_DIVIDE(
    SUM(average_speed * number_of_vehicles),
    SUM(number_of_vehicles)
  ) AS daily_avg_speed,

  SUM(number_of_vehicles) AS daily_total_vehicles

FROM `silver.traffic_density`

WHERE DATE_TIME IS NOT NULL
  AND average_speed IS NOT NULL
  AND number_of_vehicles IS NOT NULL

GROUP BY
  DATE_TIME;