/* @bruin
name: silver.hourly_traffic_density
type: bq.sql
materialization:
   type: table

depends:
   - extract_hourly_traffic_density

columns:
  - name: COORDINATE
    type: string
    description: "Coordinates of the traffic density measurement"
    checks:
      - name: not_null
@bruin */

SELECT
    *
    ,CAST(LATITUDE as STRING) || ',' || CAST(LONGITUDE as STRING) AS COORDINATE
FROM bronze.traffic_density_202405
limit 100