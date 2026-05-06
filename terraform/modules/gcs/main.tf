variable "project_id" {
  description = "The ID of the project in which to create the resources"
  type        = string
}

variable "region" {
  description = "The region in which to create the resources"
  type        = string
  default     = "us-central1"
}

variable "bucket_names" {
  description = "A map of bucket names to create"
  type        = map(string)
}

resource "google_storage_bucket" "buckets" {
  for_each = var.bucket_names

  name                        = "${var.project_id}-${each.value}"
  location                    = var.region
  force_destroy              = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

output "bucket_names" {
  value = { for k, v in google_storage_bucket.buckets : k => v.name }
}
