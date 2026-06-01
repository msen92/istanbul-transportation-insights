/* @bruin
name: silver.rail_system_stats
type: bq.sql
description: >
  "the table contains the rail system statistics of different regions of istanbul in a specified time interval"
tags:
  - rail_system_statistics
  - silver
materialization:
  type: table
  strategy: create+replace
depends:
   - bronze.rail_system_stats

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

   - name: TOWN
     type: string
     description: "the district or town where the transaction occurred"
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

   - name: LINE
     type: string
     description: "the readable name of the transport line"
     checks:
      - name: not_null

   - name: STATION_NAME
     type: int
     description: "reperesents the stations of transportation vehicles"
     checks:
      - name: not_null

   - name: STATION_NUMBER
     type: string
     description: "reperesents the code of transportation vehicles"
     checks:
      - name: not_null

   - name: PASSAGE_CNT
     type: int
     description: "The total number of card validations (tap-ins), including all transfers and multiple boardings."
     checks:
      - name: not_null
      - name: non_negative

   - name: PASSANGER_CNT
     type: int
     description: "The estimated total number of unique individual passengers."
     checks:
      - name: not_null
      - name: non_negative

   - name: AGE
     type: string
     description: "age interval of the passangers"
     checks:
      - name: not_null
custom_checks:
  - name: year-check-for-2024
    description: all dates must be from 2024
    query: SELECT count(*) as not2024 FROM `silver.rail_system_stats` WHERE EXTRACT(YEAR FROM DATE_TIME) != 2024;
    value: 0

@bruin */

SELECT 
_id as id
,DATETIME(DATE(transaction_year, transaction_month, transaction_day)) AS DATE_TIME
,COALESCE(TOWN, 'unknown') as TOWN
,COALESCE(LATITUDE, 0.0) AS LATITUDE
,COALESCE(LONGITUDE, 0.0) AS LONGITUDE
,CAST(COALESCE(LATITUDE, 0.0) as STRING) || ',' || CAST(COALESCE(LONGITUDE, 0.0) as STRING) AS COORDINATE
,LINE
,COALESCE(STATION_NAME, 'unknown') AS STATION_NAME
,COALESCE(STATION_NUMBER, 'unknown') AS STATION_NUMBER
,PASSAGE_CNT
,PASSANGER_CNT 
,AGE
FROM `bronze.rail_system_stats`
WHERE passanger_cnt > 0

