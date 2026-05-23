/* @bruin
name: gold.weekday_vs_weekend_transport_analysis
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

WITH base AS (
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
    ) AS trip_date,

    CAST(town AS STRING) AS town,

    CAST(age AS STRING) AS age_group,

    SAFE_CAST(passanger_cnt AS INT64) AS passenger_count

  FROM datapsecta-bruin.bronze.rail_systems_stats_2024

  WHERE passanger_cnt IS NOT NULL
    AND SAFE_CAST(passanger_cnt AS INT64) >= 0
),

classified AS (
  SELECT
    trip_date,

    CASE
      WHEN EXTRACT(DAYOFWEEK FROM trip_date) IN (1, 7)
        THEN 'WEEKEND'
      ELSE 'WEEKDAY'
    END AS day_type,

    town,
    age_group,
    passenger_count

  FROM base
  WHERE trip_date IS NOT NULL
),

aggregated AS (
  SELECT
    day_type,
    town,
    age_group,

    SUM(passenger_count) AS total_passengers,

    COUNT(*) AS total_records

  FROM classified
  GROUP BY
    day_type,
    town,
    age_group
),

ranked AS (
  SELECT
    day_type,
    town,
    age_group,
    total_passengers,
    total_records,

    ROUND(
      SAFE_DIVIDE(
        total_passengers,
        SUM(total_passengers) OVER (PARTITION BY day_type)
      ) * 100,
      2
    ) AS passenger_ratio_pct,

    ROW_NUMBER() OVER (
      PARTITION BY day_type
      ORDER BY total_passengers DESC
    ) AS popularity_rank

  FROM aggregated
)

SELECT
  day_type,
  town,
  age_group,
  total_passengers,
  total_records,
  passenger_ratio_pct,
  popularity_rank

FROM ranked
ORDER BY
  day_type,
  popularity_rank;