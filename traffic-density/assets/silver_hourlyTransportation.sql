/* @bruin
name: silver.hourly_transportation
type: bq.sql
description: >
  "the table contains the hourly public transportation statistics of different regions of istanbul in a specified time interval"
tags:
  - hourly_transportation
materialization:
  type: table
  strategy: create+replace

columns:
  - name: id
    type: string
    description: "unique identifier of the record"
    primary_key: true
    checks:
      - name: not_null

  - name: DATE_TIME
    type: timestamp
    description: "the date and time of the transportation transaction"
    checks:
      - name: not_null

  - name: TRANSPORT_TYPE_ID
    type: int
    description: "identifier for the type of transport vehicle or system"

  - name: ROAD_TYPE
    type: string
    description: "classification of the road or transport path"

  - name: LINE
    type: string
    description: "the specific transport line code or identifier"

  - name: TRANSFER_TYPE
    type: string
    description: "indicates if the transaction is a normal boarding or a transfer"

  - name: NUMBER_OF_PASSAGE
    type: int
    description: "the total number of card validations (tap-ins), including all transfers"
    checks:
      - name: not_null
      - name: non_negative

  - name: NUMBER_OF_PASSENGER
    type: int
    description: "the estimated total number of unique individual passengers"
    checks:
      - name: not_null
      - name: non_negative

  - name: PRODUCT_KIND
    type: string
    description: "type of the ticket or card used (e.g., full fare, student, discounted)"

  - name: TRANSACTION_TYPE_DESC
    type: string
    description: "detailed description of the transaction type"

  - name: TOWN
    type: string
    description: "the district or town where the transaction occurred"

  - name: LINE_NAME
    type: string
    description: "the readable name of the transport line"

  - name: station_poi_desc_cd
    type: string
    description: "the name of the specific station, stop, or pier"

custom_checks:
  - name: logic-passage-vs-passenger
    description: "The number of passages (NUMBER_OF_PASSAGE) must always be greater than or equal to the number of passengers (NUMBER_OF_PASSENGER)."
    query: >
      SELECT count(*) as invalid_logic_rows
      FROM `datapsecta-bruin.silver.hourly_transportation`
      WHERE NUMBER_OF_PASSENGER > NUMBER_OF_PASSAGE
    value: 0

  - name: valid-transfer-type
    description: "Ensure the TRANSFER_TYPE column only contains expected accepted values."
    query: >
      SELECT count(*) as invalid_transfer_types
      FROM `datapsecta-bruin.silver.hourly_transportation`
      WHERE TRANSFER_TYPE NOT IN ('Normal', 'Aktarma', 'Ucretsiz') 
        AND TRANSFER_TYPE IS NOT NULL
    value: 0

@bruin */

SELECT
_id as id
,DATETIME_ADD(DATETIME(transition_date), INTERVAL CAST(transition_hour AS INT) HOUR) AS DATE_TIME
,TRANSPORT_TYPE_ID
,ROAD_TYPE
,LINE
,TRANSFER_TYPE
,NUMBER_OF_PASSAGE
,NUMBER_OF_PASSENGER
,PRODUCT_KIND
,TRANSACTION_TYPE_DESC
,TOWN
,LINE_NAME
,station_poi_desc_cd 
FROM `datapsecta-bruin.bronze.hourly_transportation`
WHERE CAST(number_of_passenger AS INT) > 0
