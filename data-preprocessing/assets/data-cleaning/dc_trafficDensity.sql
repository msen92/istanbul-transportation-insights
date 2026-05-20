/* @bruin
name: gold.v2_traffic_density_202405
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
  - silver.v2_traffic_density_202405
@bruin */

SELECT *
FROM `datapsecta-bruin.silver.v2_traffic_density_202405`
WHERE (MINIMUM_SPEED > 0 AND MINIMUM_SPEED <= 200)
  AND (MAXIMUM_SPEED > 0 AND MAXIMUM_SPEED <= 200)
  AND (AVERAGE_SPEED > 0 AND AVERAGE_SPEED <= 200)