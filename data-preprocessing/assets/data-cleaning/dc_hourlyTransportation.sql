/* @bruin
name: gold.v2_hourly_transportation_202405
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
  - silver.v2_hourly_transportation_202405
@bruin */

SELECT *
FROM `datapsecta-bruin.silver.v2_hourly_transportation_202405`
WHERE number_of_passenger > 10