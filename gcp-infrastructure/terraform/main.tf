terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "vita_vpc" {
  name                    = "vita-strategies-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vita_subnet" {
  name          = "vita-strategies-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vita_vpc.id
}

# Firewall Rules
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vita_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vita_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-access"]
}

# Application Server (Single VM)
resource "google_compute_instance" "vita_server" {
  name         = "vita-strategies-server"
  machine_type = "e2-standard-4"  # 4 vCPUs, 16GB RAM
  zone         = var.zone

  tags = ["web-server", "ssh-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 100  # 100GB SSD
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.vita_vpc.name
    subnetwork = google_compute_subnetwork.vita_subnet.name
    
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/startup-scripts/install-docker.sh")

  service_account {
    email  = google_service_account.vita_service_account.email
    scopes = ["cloud-platform"]
  }
}

# Cloud SQL for ERPNext (MySQL)
resource "google_sql_database_instance" "erpnext_mysql" {
  name             = "erpnext-mysql"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro"  # Cheapest option for solo dev
    
    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }
    
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        value = google_compute_instance.vita_server.network_interface[0].access_config[0].nat_ip
      }
    }
  }

  deletion_protection = false  # Easier for development
}

resource "google_sql_database" "erpnext_db" {
  name     = "erpnext"
  instance = google_sql_database_instance.erpnext_mysql.name
}

resource "google_sql_user" "erpnext_user" {
  name     = "erpnext"
  instance = google_sql_database_instance.erpnext_mysql.name
  password = var.mysql_password
}

# PostgreSQL for other services
resource "google_sql_database_instance" "postgres" {
  name             = "vita-postgres"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-f1-micro"  # Cheapest option
    
    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }
    
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        value = google_compute_instance.vita_server.network_interface[0].access_config[0].nat_ip
      }
    }
  }

  deletion_protection = false
}

# Static IP for the server
resource "google_compute_address" "vita_ip" {
  name = "vita-strategies-ip"
}

# Assign static IP to the instance
resource "google_compute_instance" "vita_server_with_static_ip" {
  name         = "vita-strategies-server"
  machine_type = "e2-standard-4"
  zone         = var.zone

  tags = ["web-server", "ssh-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 100
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.vita_vpc.name
    subnetwork = google_compute_subnetwork.vita_subnet.name
    
    access_config {
      nat_ip = google_compute_address.vita_ip.address
    }
  }

  metadata_startup_script = file("${path.module}/startup-scripts/install-docker.sh")

  service_account {
    email  = google_service_account.vita_service_account.email
    scopes = ["cloud-platform"]
  }

  depends_on = [google_compute_address.vita_ip]
}

# Service Account
resource "google_service_account" "vita_service_account" {
  account_id   = "vita-compute-sa"
  display_name = "Vita Strategies Compute Service Account"
}

resource "google_project_iam_member" "vita_sa_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectAdmin"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.vita_service_account.email}"
}
