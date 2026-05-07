variable "project_id" {
  description = "The ID of the project"
  type        = string
}

variable "region" {
  description = "The region for BigQuery datasets"
  type        = string
}

variable "datasets" {
  description = "List of datasets to create"
  type        = list(string)
}

resource "google_bigquery_dataset" "datasets" {
  for_each = toset(var.datasets)

  dataset_id = each.value
  location   = var.region
  project    = var.project_id
}

output "dataset_ids" {
  value = { for k, v in google_bigquery_dataset.datasets : k => v.dataset_id }
}

resource "google_bigquery_connection" "biglake_connection" {
  connection_id = "biglake-connection"
  project       = var.project_id
  location      = var.region
  cloud_resource {}
}

output "biglake_connection_id" {
  value = google_bigquery_connection.biglake_connection.name
}

output "biglake_service_account" {
  value = google_bigquery_connection.biglake_connection.cloud_resource[0].service_account_id
}
