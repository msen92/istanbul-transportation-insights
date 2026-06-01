/* @bruin
name: gold.insight_lowest_speed_hours
type: bq.sql

materialization:
  type: table
  strategy: create+replace

tags:
  - gold

depends:
  - gold.hourly_mobility_summary

@bruin */

WITH base AS (
  SELECT
    analysis_date,
    analysis_hour,
    total_passengers,
    total_vehicles,
    avg_speed
  FROM gold.hourly_mobility_summary
  WHERE analysis_date BETWEEN DATE '2024-05-01' AND DATE '2024-05-31'
    AND avg_speed IS NOT NULL
    AND total_passengers IS NOT NULL
    AND total_vehicles IS NOT NULL
),

benchmark AS (
  SELECT
    AVG(total_passengers) AS avg_hourly_passengers,
    AVG(total_vehicles) AS avg_hourly_vehicles,
    AVG(avg_speed) AS avg_monthly_speed
  FROM base
),

ranked AS (
  SELECT
    b.analysis_date,
    b.analysis_hour,
    b.total_passengers,
    b.total_vehicles,
    ROUND(b.avg_speed, 2) AS avg_speed,

    ROUND(SAFE_DIVIDE(b.total_passengers, bm.avg_hourly_passengers), 2)
      AS passenger_vs_monthly_avg_ratio,

    ROUND(SAFE_DIVIDE(b.total_vehicles, bm.avg_hourly_vehicles), 2)
      AS vehicle_vs_monthly_avg_ratio,

    ROUND(bm.avg_monthly_speed, 2) AS monthly_avg_speed,

    ROW_NUMBER() OVER (
      ORDER BY b.avg_speed ASC, b.total_vehicles DESC
    ) AS congestion_rank

  FROM base AS b
  CROSS JOIN benchmark AS bm
)

SELECT
  analysis_date,
  analysis_hour,
  total_passengers,
  total_vehicles,
  avg_speed,
  monthly_avg_speed,
  passenger_vs_monthly_avg_ratio,
  vehicle_vs_monthly_avg_ratio,
  congestion_rank
FROM ranked
WHERE congestion_rank <= 20
ORDER BY congestion_rank;