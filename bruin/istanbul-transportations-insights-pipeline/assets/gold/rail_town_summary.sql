/* @bruin
name: gold.rail_town_summary
type: bq.sql

tags:
  - gold

materialization:
  type: table
  strategy: create+replace

depends:
  - silver.rail_system_stats


@bruin */

SELECT
  UPPER(TRIM(CAST(town AS STRING))) AS town,
  SUM(SAFE_CAST(passanger_cnt AS INT64)) AS total_rail_passengers
FROM silver.rail_system_stats
WHERE town IS NOT NULL
  AND TRIM(CAST(town AS STRING)) != ''
  AND passanger_cnt IS NOT NULL
  AND SAFE_CAST(passanger_cnt AS INT64) >= 0
GROUP BY
  town;