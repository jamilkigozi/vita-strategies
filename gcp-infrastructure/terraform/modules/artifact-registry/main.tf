variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "repository_id" {
  description = "ID of the artifact registry repository"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${var.repository_id}-${var.environment}"
  description   = "Docker repository for Vita Strategies ${var.environment} environment"
  format        = "DOCKER"
  project       = var.project_id

  labels = var.tags
}

# IAM binding for service accounts to pull images
resource "google_artifact_registry_repository_iam_binding" "repo_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.repo.location
  repository = google_artifact_registry_repository.repo.name
  role       = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${var.project_id}-compute@developer.gserviceaccount.com",
  ]
}
