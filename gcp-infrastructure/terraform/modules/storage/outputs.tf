output "app_bucket_name" {
  description = "Name of the application storage bucket"
  value       = google_storage_bucket.app_storage.name
}

output "backup_bucket_name" {
  description = "Name of the backup storage bucket"
  value       = google_storage_bucket.backup_storage.name
}

output "terraform_state_bucket_name" {
  description = "Name of the terraform state bucket"
  value       = google_storage_bucket.terraform_state.name
}

output "bucket_name" {
  description = "Primary bucket name (app storage)"
  value       = google_storage_bucket.app_storage.name
}
