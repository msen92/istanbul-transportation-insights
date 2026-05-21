/* @bruin
name: silver.rail_system_stats
type: bq.sql

materialization:
  type: table
  strategy: create+replace

depends:
   - rail_system_stats_2024

@bruin */

SELECT 
    _id,
    DATETIME(DATE(transaction_year, transaction_month, transaction_day)) AS transaction_datetime,
    * EXCEPT(_id, transaction_year, transaction_month, transaction_day)
FROM `datapsecta-bruin.bronze.rail_system_stats`
WHERE passanger_cnt > 0