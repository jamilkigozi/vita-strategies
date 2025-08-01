variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_name" {
  description = "Name of the VM instance"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "e2-micro"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "vpc_network" {
  description = "VPC network self link"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "Startup script for the instance"
  type        = string
  default     = ""
}

# Get the latest Ubuntu 22.04 LTS image
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# VM Instance
resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.vpc_network
    subnetwork = var.subnet_name

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = var.startup_script != "" ? var.startup_script : templatefile("${path.module}/startup-script.sh", {
    environment = var.environment
  })

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["vita-vm", var.environment]

  labels = var.tags
}

# Firewall rule for HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.instance_name}-allow-web"
  network = var.vpc_network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vita-vm"]
}

# Firewall rule for SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.instance_name}-allow-ssh"
  network = var.vpc_network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vita-vm"]
}