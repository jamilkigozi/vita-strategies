output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_self_link" {
  description = "The self link of the VPC"
  value       = module.vpc.vpc_self_link
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = module.vpc.subnet_id
}

output "database_connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = module.cloudsql.connection_name
}

output "database_private_ip" {
  description = "The private IP of the Cloud SQL instance"
  value       = module.cloudsql.private_ip_address
}

output "vm_external_ip" {
  description = "External IP of the VM instance"
  value       = module.vm.external_ip
}

output "vm_internal_ip" {
  description = "Internal IP of the VM instance"
  value       = module.vm.internal_ip
}

output "load_balancer_ip" {
  description = "External IP of the load balancer"
  value       = module.lb.external_ip
}

output "storage_bucket_name" {
  description = "Name of the storage bucket"
  value       = module.storage.bucket_name
}

output "artifact_registry_url" {
  description = "URL of the artifact registry"
  value       = module.artifact_registry.repository_url
}
