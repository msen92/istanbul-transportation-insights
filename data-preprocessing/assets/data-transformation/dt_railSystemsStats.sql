/* @bruin
name: silver.v2_rail_systems_stats_2024
type: bq.sql

materialization:
  type: table
  strategy: create+replace

@bruin */

SELECT 
    id,
    DATETIME(DATE(transaction_year, transaction_month, transaction_day)) AS transaction_datetime,
    * EXCEPT(id, transaction_year, transaction_month, transaction_day)
FROM `datapsecta-bruin.bronze.rail_systems_stats_2024`