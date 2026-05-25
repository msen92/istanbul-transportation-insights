/* @bruin
name: silver.rail_town_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT
  UPPER(TRIM(CAST(town AS STRING))) AS town,
  SUM(SAFE_CAST(passanger_cnt AS INT64)) AS total_rail_passengers
FROM datapsecta-bruin.bronze.rail_systems_stats_2024
WHERE town IS NOT NULL
  AND TRIM(CAST(town AS STRING)) != ''
  AND passanger_cnt IS NOT NULL
  AND SAFE_CAST(passanger_cnt AS INT64) >= 0
GROUP BY
  town;