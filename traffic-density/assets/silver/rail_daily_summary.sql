/* @bruin
name: silver.rail_daily_summary
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT
  SAFE.PARSE_DATE(
    '%Y-%m-%d',
    CONCAT(
      CAST(transaction_year AS STRING),
      '-',
      LPAD(CAST(transaction_month AS STRING), 2, '0'),
      '-',
      LPAD(CAST(transaction_day AS STRING), 2, '0')
    )
  ) AS rail_date,

  SUM(SAFE_CAST(passanger_cnt AS INT64)) AS total_rail_passengers

FROM datapsecta-bruin.bronze.rail_systems_stats_2024

WHERE transaction_year IS NOT NULL
  AND transaction_month IS NOT NULL
  AND transaction_day IS NOT NULL
  AND passanger_cnt IS NOT NULL
  AND SAFE_CAST(passanger_cnt AS INT64) >= 0

GROUP BY
  rail_date;