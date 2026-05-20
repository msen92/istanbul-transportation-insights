/* @bruin
name: silver.v2_hourly_transportation_202405
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT 
    DATETIME_ADD(DATETIME(transition_date), INTERVAL transition_hour HOUR) AS transition_datetime,
    * EXCEPT(transition_date, transition_hour)
FROM `datapsecta-bruin.bronze.hourly_transportation_202405`