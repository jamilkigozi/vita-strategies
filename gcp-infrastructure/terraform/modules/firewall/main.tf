variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_network" {
  description = "VPC network name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "${var.vpc_network}-allow-http"
  network = var.vpc_network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Allow HTTPS traffic
resource "google_compute_firewall" "allow_https" {
  name    = "${var.vpc_network}-allow-https"
  network = var.vpc_network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

# Allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vpc_network}-allow-ssh"
  network = var.vpc_network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-access"]
}

# Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_network}-allow-internal"
  network = var.vpc_network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

# Allow application ports
resource "google_compute_firewall" "allow_app_ports" {
  name    = "${var.vpc_network}-allow-apps"
  network = var.vpc_network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["3000", "5432", "8000", "8065", "8080", "8443", "9090", "9093"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vita-apps"]
}
