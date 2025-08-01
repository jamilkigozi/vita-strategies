variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
}

variable "vpc_network" {
  description = "VPC network self link"
  type        = string
}

variable "backend_vms" {
  description = "List of backend VM self links"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Health check for backend instances
resource "google_compute_health_check" "default" {
  name     = "${var.lb_name}-health-check"
  project  = var.project_id

  timeout_sec        = 5
  check_interval_sec = 5

  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

# Backend service
resource "google_compute_backend_service" "default" {
  name        = "${var.lb_name}-backend"
  protocol    = "HTTP"
  timeout_sec = 10
  project     = var.project_id

  health_checks = [google_compute_health_check.default.id]

  dynamic "backend" {
    for_each = var.backend_vms
    content {
      group = backend.value
    }
  }
}

# URL map
resource "google_compute_url_map" "default" {
  name            = "${var.lb_name}-url-map"
  default_service = google_compute_backend_service.default.id
  project         = var.project_id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.default.id
    }
  }
}

# HTTP(S) proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.lb_name}-http-proxy"
  url_map = google_compute_url_map.default.id
  project = var.project_id
}

# Global forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.lb_name}-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  project    = var.project_id
}
