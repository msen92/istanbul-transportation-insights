/* @bruin
name: gold.town_transport_mode_ratio
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
  - silver.rail_town_summary
  - silver.transportation_town_mode_summary

@bruin */

WITH transportation_pivot AS (
  SELECT
    town,

    SUM(
      CASE
        WHEN road_type = 'OTOYOL' THEN total_passengers
        ELSE 0
      END
    ) AS total_road_passengers,

    SUM(
      CASE
        WHEN road_type LIKE 'DEN%' THEN total_passengers
        ELSE 0
      END
    ) AS total_sea_passengers,

    SUM(
      CASE
        WHEN road_type = 'RAYLI' THEN total_passengers
        ELSE 0
      END
    ) AS total_hourly_rail_passengers,

    SUM(total_passengers) AS total_hourly_transportation_passengers

  FROM datapsecta-bruin.silver.transportation_town_mode_summary
  GROUP BY
    town
),

base AS (
  SELECT
    COALESCE(r.town, t.town) AS town,

    COALESCE(r.total_rail_passengers, 0) AS total_rail_passengers,
    COALESCE(t.total_road_passengers, 0) AS total_road_passengers,
    COALESCE(t.total_sea_passengers, 0) AS total_sea_passengers,
    COALESCE(t.total_hourly_rail_passengers, 0) AS total_hourly_rail_passengers,
    COALESCE(t.total_hourly_transportation_passengers, 0) AS total_hourly_transportation_passengers

  FROM datapsecta-bruin.silver.rail_town_summary AS r
  FULL OUTER JOIN transportation_pivot AS t
    ON r.town = t.town
),

final AS (
  SELECT
    town,
    total_rail_passengers,
    total_road_passengers,
    total_sea_passengers,
    total_hourly_rail_passengers,
    total_hourly_transportation_passengers,

    total_rail_passengers
      + total_road_passengers
      + total_sea_passengers AS total_compared_passengers

  FROM base
)

SELECT
  town,

  total_rail_passengers,
  total_road_passengers,
  total_sea_passengers,
  total_hourly_rail_passengers,
  total_hourly_transportation_passengers,
  total_compared_passengers,

  ROUND(
    SAFE_DIVIDE(total_rail_passengers, total_compared_passengers) * 100,
    2
  ) AS rail_usage_ratio_pct,

  ROUND(
    SAFE_DIVIDE(total_road_passengers, total_compared_passengers) * 100,
    2
  ) AS road_usage_ratio_pct,

  ROUND(
    SAFE_DIVIDE(total_sea_passengers, total_compared_passengers) * 100,
    2
  ) AS sea_usage_ratio_pct,

  CASE
    WHEN total_rail_passengers >= total_road_passengers
     AND total_rail_passengers >= total_sea_passengers
      THEN 'RAYLI SISTEM AGIRLIKLI'

    WHEN total_road_passengers >= total_rail_passengers
     AND total_road_passengers >= total_sea_passengers
      THEN 'KARAYOLU AGIRLIKLI'

    WHEN total_sea_passengers >= total_rail_passengers
     AND total_sea_passengers >= total_road_passengers
      THEN 'DENIZ ULASIMI AGIRLIKLI'

    ELSE 'BELIRSIZ'
  END AS dominant_transport_type

FROM final
WHERE total_compared_passengers > 0
ORDER BY
  total_compared_passengers DESC;