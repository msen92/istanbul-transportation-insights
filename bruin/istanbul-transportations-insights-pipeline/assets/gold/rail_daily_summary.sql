/* @bruin
name: gold.rail_daily_summary
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

FROM silver.rail_system_stats

WHERE transaction_year IS NOT NULL
  AND transaction_month IS NOT NULL
  AND transaction_day IS NOT NULL
  AND passanger_cnt IS NOT NULL
  AND SAFE_CAST(passanger_cnt AS INT64) >= 0

GROUP BY
  rail_date;