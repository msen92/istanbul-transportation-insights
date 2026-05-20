/* @bruin
name: silver.v2_traffic_density_202405
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT 
    _id,
    DATETIME(DATE_TIME) AS DATE_TIME,
    * EXCEPT(_id, DATE_TIME)
FROM `datapsecta-bruin.bronze.traffic_density_202405`