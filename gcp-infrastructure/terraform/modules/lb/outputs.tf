output "external_ip" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.default.ip_address
}

output "backend_service_id" {
  description = "ID of the backend service"
  value       = google_compute_backend_service.default.id
}

output "url_map_id" {
  description = "ID of the URL map"
  value       = google_compute_url_map.default.id
}
