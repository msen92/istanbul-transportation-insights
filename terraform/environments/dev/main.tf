terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    # Bucket name will be passed via backend config or CLI
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "gcs" {
  source     = "../../modules/gcs"
  project_id = var.project_id
  region     = var.region
  bucket_names = {
    bronze = "bronze-lake"
    silver = "silver-lake"
  }
}

module "bigquery" {
  source     = "../../modules/bigquery"
  project_id = var.project_id
  region     = var.region
  datasets   = ["bronze", "silver", "gold"]
}

module "iam" {
  source                  = "../../modules/iam"
  project_id              = var.project_id
  bucket_names            = [module.gcs.bucket_names["bronze"], module.gcs.bucket_names["silver"]]
  biglake_service_account = module.bigquery.biglake_service_account
}

# Bronze External Tables (BigLake)
resource "google_bigquery_table" "traffic_density_bronze" {
  dataset_id = module.bigquery.dataset_ids["bronze"]
  table_id   = "traffic_density"
  deletion_protection = false

  schema = <<EOF
[
  {"name": "_id", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "DATE_TIME", "type": "STRING", "mode": "NULLABLE"},
  {"name": "LATITUDE", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "LONGITUDE", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "GEOHASH", "type": "STRING", "mode": "NULLABLE"},
  {"name": "MINIMUM_SPEED", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "MAXIMUM_SPEED", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "AVERAGE_SPEED", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "NUMBER_OF_VEHICLES", "type": "INTEGER", "mode": "NULLABLE"}
]
EOF

  external_data_configuration {
    autodetect    = false
    source_format = "NEWLINE_DELIMITED_JSON"
    source_uris   = ["gs://${module.gcs.bucket_names["bronze"]}/traffic_density/*.json"]
    connection_id = module.bigquery.biglake_connection_id
  }
}

resource "google_bigquery_table" "hourly_transportation_bronze" {
  dataset_id          = module.bigquery.dataset_ids["bronze"]
  table_id            = "hourly_transportation"
  deletion_protection = false

  schema = <<EOF
[
  {"name": "_id", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "transition_date", "type": "DATE", "mode": "NULLABLE"},
  {"name": "transition_hour", "type": "STRING", "mode": "NULLABLE"},
  {"name": "transport_type_id", "type": "STRING", "mode": "NULLABLE"},
  {"name": "road_type", "type": "STRING", "mode": "NULLABLE"},
  {"name": "line", "type": "STRING", "mode": "NULLABLE"},
  {"name": "transfer_type", "type": "STRING", "mode": "NULLABLE"},
  {"name": "number_of_passage", "type": "STRING", "mode": "NULLABLE"},
  {"name": "number_of_passenger", "type": "STRING", "mode": "NULLABLE"},
  {"name": "product_kind", "type": "STRING", "mode": "NULLABLE"},
  {"name": "transaction_type_desc", "type": "STRING", "mode": "NULLABLE"},
  {"name": "town", "type": "STRING", "mode": "NULLABLE"},
  {"name": "line_name", "type": "STRING", "mode": "NULLABLE"},
  {"name": "station_poi_desc_cd", "type": "STRING", "mode": "NULLABLE"}
]
EOF

  external_data_configuration {
    autodetect    = false
    source_format = "PARQUET"
    source_uris   = ["gs://${module.gcs.bucket_names["bronze"]}/hourly_transportation/*.parquet"]
    connection_id = module.bigquery.biglake_connection_id
  }
}


resource "google_bigquery_table" "rail_system_stats_bronze" {
  dataset_id = module.bigquery.dataset_ids["bronze"]
  table_id   = "rail_system_stats"
  deletion_protection = false

  schema = <<EOF
[
  {"name": "_id", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "transaction_year", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "transaction_month", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "transaction_day", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "line", "type": "STRING", "mode": "NULLABLE"},
  {"name": "station_name", "type": "STRING", "mode": "NULLABLE"},
  {"name": "station_number", "type": "STRING", "mode": "NULLABLE"},
  {"name": "age", "type": "STRING", "mode": "NULLABLE"},
  {"name": "town", "type": "STRING", "mode": "NULLABLE"},
  {"name": "longitude", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "latitude", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "passage_cnt", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "passanger_cnt", "type": "INTEGER", "mode": "NULLABLE"}
]
EOF

  external_data_configuration {
    autodetect    = false
    source_format = "NEWLINE_DELIMITED_JSON"
    source_uris   = ["gs://${module.gcs.bucket_names["bronze"]}/rail_system_stats/*.json"]
    connection_id = module.bigquery.biglake_connection_id
  }
}

# Silver Tables (BigLake Managed Iceberg Tables)
# Note: We commented these out because BigQuery requires the Iceberg metadata files 
# to exist in GCS before the table can be defined in Terraform.
# Once you upload data and run the "Initialize" procedure below, you can uncomment these.

/*
resource "google_bigquery_table" "traffic_density_silver" {
  dataset_id = "silver"
  table_id   = "traffic_density"
  deletion_protection = false

  external_data_configuration {
    source_format = "ICEBERG"
    connection_id = module.bigquery.biglake_connection_id
    source_uris   = ["gs://${module.gcs.bucket_names["silver"]}/traffic_density/metadata/*.json"]
    autodetect    = true
  }
}
*/
