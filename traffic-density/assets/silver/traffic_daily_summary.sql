/* @bruin
name: silver.traffic_daily_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
  - silver.traffic_hourly_summary

@bruin */

SELECT
  traffic_date,

  SAFE_DIVIDE(
    SUM(avg_traffic_speed * total_number_of_vehicles),
    SUM(total_number_of_vehicles)
  ) AS daily_avg_speed,

  SUM(total_number_of_vehicles) AS daily_total_vehicles

FROM datapsecta-bruin.silver.traffic_hourly_summary
WHERE traffic_date IS NOT NULL
  AND avg_traffic_speed IS NOT NULL
  AND total_number_of_vehicles IS NOT NULL
GROUP BY
  traffic_date;