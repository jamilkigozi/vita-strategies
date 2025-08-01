output "instance_id" {
  description = "The ID of the VM instance"
  value       = google_compute_instance.vm.instance_id
}

output "instance_self_link" {
  description = "The self link of the VM instance"
  value       = google_compute_instance.vm.self_link
}

output "external_ip" {
  description = "External IP address of the VM instance"
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "Internal IP address of the VM instance"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "instance_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.vm.name
}
