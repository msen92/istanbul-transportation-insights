/* @bruin
name: gold.daily_combo_chart_data
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
  - gold.daily_mobility_summary

@bruin */

SELECT
  EXTRACT(DAY FROM analysis_date) AS may_day,
  analysis_date,
  total_rail_passengers + total_road_passengers AS total_passengers,
  ROUND(daily_avg_speed, 2) AS avg_traffic_speed
FROM datapsecta-bruin.gold.daily_mobility_summary
ORDER BY analysis_date;