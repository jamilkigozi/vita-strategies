output "repository_url" {
  description = "URL of the artifact registry repository"
  value       = "${google_artifact_registry_repository.repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

output "repository_name" {
  description = "Name of the artifact registry repository"
  value       = google_artifact_registry_repository.repo.name
}
