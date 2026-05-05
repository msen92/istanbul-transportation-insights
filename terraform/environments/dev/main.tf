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
  bucket_names            = values(module.gcs.bucket_names)
  biglake_service_account = module.bigquery.biglake_service_account
}

# Bronze External Tables (BigLake)
resource "google_bigquery_table" "traffic_density_bronze" {
  dataset_id = "bronze"
  table_id   = "traffic_density"
  deletion_protection = false

  schema = <<EOF
[
  {"name": "DATE_TIME", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "LATITUDE", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "LONGITUDE", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "GEOHASH", "type": "STRING", "mode": "NULLABLE"},
  {"name": "MINIMUM_SPEED", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "MAXIMUM_SPEED", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "AVERAGE_SPEED", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "NUMBER_OF_VEHICLES", "type": "INTEGER", "mode": "NULLABLE"}
]
EOF

  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${module.gcs.bucket_names["bronze"]}/traffic_density/*.csv"]
    connection_id = module.bigquery.biglake_connection_id
    
    csv_options {
      skip_leading_rows = 1
      quote             = "\""
    }
  }
}

resource "google_bigquery_table" "hourly_transportation_bronze" {
  dataset_id = "bronze"
  table_id   = "hourly_transportation"
  deletion_protection = false

  schema = <<EOF
[
  {"name": "transition_date", "type": "DATE", "mode": "NULLABLE"},
  {"name": "transition_hour", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "transport_type_id", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "road_type", "type": "STRING", "mode": "NULLABLE"},
  {"name": "line", "type": "STRING", "mode": "NULLABLE"},
  {"name": "transfer_type", "type": "STRING", "mode": "NULLABLE"},
  {"name": "number_of_passage", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "number_of_passenger", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "product_kind", "type": "STRING", "mode": "NULLABLE"},
  {"name": "transaction_type_desc", "type": "STRING", "mode": "NULLABLE"},
  {"name": "town", "type": "STRING", "mode": "NULLABLE"},
  {"name": "line_name", "type": "STRING", "mode": "NULLABLE"},
  {"name": "station_poi_desc_cd", "type": "STRING", "mode": "NULLABLE"}
]
EOF

  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${module.gcs.bucket_names["bronze"]}/hourly_transportation/*.csv"]
    connection_id = module.bigquery.biglake_connection_id
    
    csv_options {
      skip_leading_rows = 1
      quote             = "\""
    }
  }
}

# Silver Tables (BigLake Managed Iceberg Tables)
# BigQuery will manage the Iceberg metadata in GCS
resource "google_bigquery_table" "traffic_density_silver" {
  dataset_id = "silver"
  table_id   = "traffic_density"
  deletion_protection = false

  external_data_configuration {
    source_format = "ICEBERG"
    connection_id = module.bigquery.biglake_connection_id
    # We point to a folder where BigQuery will manage the Iceberg metadata
    source_uris   = ["gs://${module.gcs.bucket_names["silver"]}/traffic_density/metadata/*.json"]
    autodetect    = true
  }
}