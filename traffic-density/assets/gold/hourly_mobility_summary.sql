/* @bruin
name: gold.hourly_mobility_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

tags:
  - gold

depends:
  - gold.traffic_hourly_summary
  - gold.transportation_hourly_summary

@bruin */

SELECT
  t.traffic_date AS analysis_date,
  t.traffic_hour AS analysis_hour,
  tr.total_number_of_passengers AS total_passengers,
  t.total_number_of_vehicles AS total_vehicles,
  t.avg_traffic_speed AS avg_speed
FROM gold.traffic_hourly_summary AS t
INNER JOIN gold.transportation_hourly_summary AS tr
  ON t.traffic_date = tr.transportation_date
 AND t.traffic_hour = tr.transportation_hour;