/* @bruin
name: silver.traffic_density
type: bq.sql
description: >
  "the table contains the traffic density of different regions of istanbul in a specified time interval"
tags:
  - traffic_density
  - silver
materialization:
  type: table
  strategy: create+replace
depends:
   - bronze.traffic_density

columns:
   - name: id
     type: int
     description: "unique id of the a record"
     primary_key: true
     checks:
       - name: not_null

   - name: DATE_TIME
     type: DATETIME
     description: "the date of the record"
     checks:
      - name: not_null

   - name: LATITUDE
     type: float
     description: "a geographic coordinate that specifies the north-south position of a location"
     checks:
      - name: not_null

   - name: LONGITUDE
     type: float
     description: "a geographic coordinate that specifies the east-west position of a location"
     checks:
      - name: not_null

   - name: COORDINATE
     type: string
     description: "Coordinates of the traffic density measurement, derived by latitude and longitude"
     checks:
      - name: not_null
      
   - name: GEOHASH
     type: string
     description: "a public domain code that compresses latitude and longitude into a short string of letters and numbers"
     checks:
      - name: not_null

   - name: NUMBER_OF_VEHICLES
     type: int
     description: "number of vehicles in a location in a specific time interval"
     checks:
      - name: not_null
      - name: non_negative

   - name: MINIMUM_SPEED
     type: float
     description: "observed minimum speed in given coordinates"
     checks:
      - name: not_null
      - name: non_negative
      
   - name: MAXIMUM_SPEED
     type: float
     description: "observed maximum speed in given coordinates"
     checks:
      - name: not_null
      - name: non_negative

   - name: AVERAGE_SPEED
     type: float
     description: "observed average speed in given coordinates"
     checks:
      - name: not_null
      - name: non_negative

custom_checks:
  - name: year-check-for-2024
    description: all dates must be from 2024
    query: SELECT count(*) as not2024 FROM `silver.traffic_density` WHERE EXTRACT(YEAR FROM DATE_TIME) != 2024;
    value: 0

  - name: valid-geohash-check
    description: ensure all geohashes contain only valid base32 characters
    query: >
      SELECT count(*) as invalid_geohashes 
      FROM `silver.traffic_density` 
      WHERE NOT REGEXP_CONTAINS(GEOHASH, r'^[0123456789bcdefghjkmnpqrstuvwxyz]+$')
      OR GEOHASH IS NULL
    value: 0

  - name: istanbul-coordinates-check
    description: ensure coordinates are within istanbul bounds (Latitude 40.7-41.6, Longitude 27.9-29.9)
    query: >
      SELECT count(*) as invalid_coords 
      FROM `silver.traffic_density` 
      WHERE LATITUDE < 40.7 OR LATITUDE > 41.6 
         OR LONGITUDE < 27.9 OR LONGITUDE > 29.9
         OR LATITUDE IS NULL OR LONGITUDE IS NULL
    value: 0

@bruin */

SELECT 
  _id as id
  ,DATETIME(DATE_TIME) AS DATE_TIME
  ,LATITUDE
  ,LONGITUDE
  ,CAST(LATITUDE as STRING) || ',' || CAST(LONGITUDE as STRING) AS COORDINATE
  ,GEOHASH
  ,NUMBER_OF_VEHICLES
  ,MINIMUM_SPEED
  ,MAXIMUM_SPEED
  ,AVERAGE_SPEED
FROM `bronze.traffic_density`
WHERE (MINIMUM_SPEED > 0 AND MINIMUM_SPEED <= 200)
  AND (MAXIMUM_SPEED > 0 AND MAXIMUM_SPEED <= 200)
  AND (AVERAGE_SPEED > 0 AND AVERAGE_SPEED <= 200)

