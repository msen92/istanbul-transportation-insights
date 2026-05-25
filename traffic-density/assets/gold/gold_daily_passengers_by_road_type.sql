/* @bruin
name: gold.daily_passengers_by_road_type
type: bq.sql
description: "Gold layer table containing the daily total number of passengers categorized by road type for May."
tags:
  - daily_passengers_by_road_type
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

  - name: ROAD_TYPE
    type: string
    description: "Classification of the road or transport path"
    checks:
      - name: not_null

  - name: TOTAL_PASSENGER
    type: integer
    description: "The total number of passengers for the given date and road type"
    checks:
      - name: not_null
      - name: positive
@bruin */

SELECT
  DATE(DATE_TIME) AS DATE_TIME,
  ROAD_TYPE,
  SUM(CAST(NUMBER_OF_PASSENGER AS INT64)) AS TOTAL_PASSENGER
FROM
  `datapsecta-bruin.silver.hourly_transportation`
WHERE
  EXTRACT(MONTH FROM DATE_TIME) = 5
GROUP BY
  DATE(DATE_TIME),
  ROAD_TYPE
ORDER BY
  DATE(DATE_TIME),
  ROAD_TYPE