/* @bruin
name: silver.hourly_transportation
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT
    DATETIME_ADD(DATETIME(transition_date), INTERVAL CAST(transition_hour AS INT) HOUR) AS transition_datetime,
    * EXCEPT(transition_date, transition_hour)
FROM `datapsecta-bruin.bronze.hourly_transportation`
WHERE CAST(number_of_passenger AS INT) > 0