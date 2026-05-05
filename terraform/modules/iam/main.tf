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

resource "google_storage_bucket_iam_member" "biglake_gcs_reader" {
  for_each = toset(var.bucket_names)
  bucket   = each.value
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${var.biglake_service_account}"
}

# Add other IAM roles as needed
