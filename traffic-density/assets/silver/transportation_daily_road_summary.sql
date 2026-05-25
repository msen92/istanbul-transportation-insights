/* @bruin
name: silver.transportation_daily_road_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT
  SAFE_CAST(transition_date AS DATE) AS transportation_date,

  SUM(SAFE_CAST(number_of_passenger AS INT64)) AS total_road_passengers

FROM datapsecta-bruin.bronze.hourly_transportation
WHERE transition_date IS NOT NULL
  AND number_of_passenger IS NOT NULL
  AND SAFE_CAST(number_of_passenger AS INT64) >= 0
  AND UPPER(TRIM(road_type)) = 'OTOYOL'
GROUP BY
  transportation_date;