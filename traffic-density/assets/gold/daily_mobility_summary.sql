/* @bruin
name: gold.daily_mobility_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
  - silver.rail_daily_summary
  - silver.transportation_daily_road_summary
  - silver.traffic_daily_summary

@bruin */

SELECT
  r.rail_date AS analysis_date,

  r.total_rail_passengers AS total_rail_passengers,

  road.total_road_passengers AS total_road_passengers,

  traffic.daily_avg_speed AS daily_avg_speed

FROM datapsecta-bruin.silver.rail_daily_summary AS r

INNER JOIN datapsecta-bruin.silver.transportation_daily_road_summary AS road
  ON r.rail_date = road.transportation_date

INNER JOIN datapsecta-bruin.silver.traffic_daily_summary AS traffic
  ON r.rail_date = traffic.traffic_date;