/* @bruin
name: gold.v2_rail_systems_stats_2024
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
  - silver.v2_rail_systems_stats_2024
@bruin */

SELECT 
    * EXCEPT(longitude, latitude, station_number, station_name)
FROM `datapsecta-bruin.silver.v2_rail_systems_stats_2024`
WHERE passanger_cnt > 0