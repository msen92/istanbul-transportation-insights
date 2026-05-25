/* @bruin
name: gold.daily_total_passengers
type: bq.sql
description: "Gold layer (summary) table containing the daily total number of passengers for May."
tags:
  - daily_total_passengers
depends:
  - silver.hourly_transportation
materialization:
  type: table
  strategy: create+replace

columns:
  - name: DATE_TIME
    type: date
    description: "The date the transportation transactions occurred"
    checks:
      - name: not_null
      - name: unique

  - name: TOTAL_PASSENGER
    type: integer
    description: "The total number of passengers for the given date"
    checks:
      - name: not_null
      - name: positive
@bruin */

SELECT
  DATE(DATE_TIME) AS DATE_TIME,
  SUM(CAST(NUMBER_OF_PASSENGER AS INT64)) AS TOTAL_PASSENGER
FROM
  `datapsecta-bruin.silver.hourly_transportation`
WHERE
  EXTRACT(MONTH FROM DATE_TIME) = 5
GROUP BY
  DATE(DATE_TIME)
ORDER BY
  DATE(DATE_TIME)