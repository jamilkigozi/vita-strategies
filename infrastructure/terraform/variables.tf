variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "The project name for resource naming"
  type        = string
  default     = "vita-strategies"
}

variable "environment" {
  description = "The environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "europe-west2"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "europe-west2-c"
}

variable "machine_type" {
  description = "The machine type for the VM"
  type        = string
  default     = "e2-standard-4"
}

variable "boot_image" {
  description = "The boot image for the VM"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "disk_size" {
  description = "The disk size for the VM in GB"
  type        = number
  default     = 50
}

variable "domain_name" {
  description = "The domain name"
  type        = string
  default     = "vitastrategies.com"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "database_subnet_cidr" {
  description = "The CIDR block for the database subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "bucket_names" {
  description = "List of bucket names to create"
  type        = list(string)
  default     = []
}

variable "database_passwords" {
  description = "Database passwords for each service"
  type        = map(string)
  default     = {}
  sensitive   = true
}