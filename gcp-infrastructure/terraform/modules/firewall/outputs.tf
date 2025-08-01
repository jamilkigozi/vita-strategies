output "http_firewall_id" {
  description = "ID of the HTTP firewall rule"
  value       = google_compute_firewall.allow_http.id
}

output "https_firewall_id" {
  description = "ID of the HTTPS firewall rule"
  value       = google_compute_firewall.allow_https.id
}

output "ssh_firewall_id" {
  description = "ID of the SSH firewall rule"
  value       = google_compute_firewall.allow_ssh.id
}
