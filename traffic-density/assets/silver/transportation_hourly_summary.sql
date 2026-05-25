/* @bruin
name: silver.transportation_hourly_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT
  SAFE_CAST(transition_date AS DATE) AS transportation_date,
  SAFE_CAST(transition_hour AS INT64) AS transportation_hour,
  SUM(SAFE_CAST(number_of_passenger AS INT64)) AS total_number_of_passengers
FROM datapsecta-bruin.bronze.hourly_transportation
WHERE transition_date IS NOT NULL
  AND transition_hour IS NOT NULL
  AND number_of_passenger IS NOT NULL
  AND SAFE_CAST(number_of_passenger AS INT64) >= 0
GROUP BY
  transportation_date,
  transportation_hour;