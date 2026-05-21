/* @bruin
name: silver.traffic_density
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
   - extract_hourly_traffic_density_202405

columns:
   - name: COORDINATE
     type: string
     description: "Coordinates of the traffic density measurement"
     checks:
      - name: not_null

@bruin */

SELECT 
    _id,
    DATETIME(DATE_TIME) AS DATE_TIME,
    CAST(LATITUDE as STRING) || ',' || CAST(LONGITUDE as STRING) AS COORDINATE,
    * EXCEPT(_id, DATE_TIME)
FROM `datapsecta-bruin.bronze.traffic_density`
WHERE (MINIMUM_SPEED > 0 AND MINIMUM_SPEED <= 200)
  AND (MAXIMUM_SPEED > 0 AND MAXIMUM_SPEED <= 200)
  AND (AVERAGE_SPEED > 0 AND AVERAGE_SPEED <= 200)