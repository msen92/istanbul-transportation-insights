/* @bruin
name: gold.top_10_geohash_regions
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
  - silver.traffic_hourly_summary

@bruin */

WITH geohash_base AS (
  SELECT
    GEOHASH AS geohash_region,

    SAFE_CAST(NUMBER_OF_VEHICLES AS INT64) AS vehicle_count,

    SAFE_CAST(AVERAGE_SPEED AS FLOAT64) AS average_speed

  FROM datapsecta-bruin.bronze.traffic_density

  WHERE GEOHASH IS NOT NULL
    AND TRIM(GEOHASH) != ''
    AND NUMBER_OF_VEHICLES IS NOT NULL
    AND SAFE_CAST(NUMBER_OF_VEHICLES AS INT64) >= 0
),

aggregated AS (
  SELECT
    geohash_region,

    SUM(vehicle_count) AS total_vehicles,

    ROUND(AVG(average_speed), 2) AS avg_speed,

    COUNT(*) AS total_measurements

  FROM geohash_base
  GROUP BY
    geohash_region
),
ranked AS (
  SELECT
    geohash_region,
    total_vehicles,
    avg_speed,
    total_measurements,

    ROW_NUMBER() OVER (
      ORDER BY total_vehicles DESC
    ) AS traffic_density_rank

  FROM aggregated
)

SELECT
  geohash_region,
  total_vehicles,
  avg_speed,
  total_measurements,
  traffic_density_rank

FROM ranked
WHERE traffic_density_rank <= 10
ORDER BY
  traffic_density_rank;