/* @bruin
name: gold.traffic_hourly_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT
  DATE(DATE_TIME) AS traffic_date,
  EXTRACT(HOUR FROM DATE_TIME) AS traffic_hour,
  AVG(AVERAGE_SPEED) AS avg_traffic_speed,
  SUM(NUMBER_OF_VEHICLES) AS total_number_of_vehicles
FROM `datapsecta-bruin.silver.traffic_density`
WHERE DATE_TIME IS NOT NULL
  AND AVERAGE_SPEED IS NOT NULL
  AND NUMBER_OF_VEHICLES IS NOT NULL
  AND AVERAGE_SPEED > 0
  AND AVERAGE_SPEED <= 200
  AND NUMBER_OF_VEHICLES >= 0
GROUP BY
  traffic_date,
  traffic_hour;