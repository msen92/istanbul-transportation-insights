variable "project_id" {
  description = "The ID of the project"
  type        = string
}

variable "bucket_names" {
  description = "List of bucket names"
  type        = list(string)
}

variable "biglake_service_account" {
  description = "The service account for BigLake connection"
  type        = string
}

# 1. BigLake Connection Permissions
resource "google_storage_bucket_iam_member" "biglake_gcs_reader" {
  for_each = toset(var.bucket_names)
  bucket   = each.value
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${var.biglake_service_account}"
}

resource "google_storage_bucket_iam_member" "biglake_gcs_writer" {
  bucket = var.bucket_names[1] # Silver bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.biglake_service_account}"
}

# 2. Application Service Account (for Ingestion/Processing)
resource "google_service_account" "app_sa" {
  account_id   = "lakehouse-app-sa"
  display_name = "Lakehouse Application Service Account"
}

# 2a. BigQuery Permissions for App SA
resource "google_project_iam_member" "app_sa_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_project_iam_member" "app_sa_bq_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# 2b. GCS Permissions for App SA
resource "google_storage_bucket_iam_member" "app_sa_storage_admin" {
  for_each = toset(var.bucket_names)
  bucket   = each.value
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${google_service_account.app_sa.email}"
}

output "app_service_account_email" {
  value = google_service_account.app_sa.email
}
