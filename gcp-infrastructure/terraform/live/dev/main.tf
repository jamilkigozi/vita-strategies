terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "vita-strategies-terraform-state-dev"
    prefix = "dev/terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Local variables
locals {
  environment = "dev"
  common_tags = {
    Environment = local.environment
    Project     = "vita-strategies"
    ManagedBy   = "terraform"
  }
}

# VPC Network
module "vpc" {
  source = "../../modules/vpc"
  
  project_id          = var.project_id
  environment         = local.environment
  vpc_name           = "vita-vpc-${local.environment}"
  subnet_cidr        = "10.0.0.0/24"
  region             = var.region
  enable_nat_gateway = true
  
  tags = local.common_tags
}

# Cloud SQL Instance
module "cloudsql" {
  source = "../../modules/cloudsql"
  
  project_id     = var.project_id
  environment    = local.environment
  instance_name  = "vita-db-${local.environment}"
  database_name  = "vita_platform"
  region         = var.region
  vpc_network    = module.vpc.vpc_self_link
  
  tags = local.common_tags
}

# Compute Engine VM
module "vm" {
  source = "../../modules/vm"
  
  project_id      = var.project_id
  environment     = local.environment
  instance_name   = "vita-app-${local.environment}"
  machine_type    = "e2-standard-2"
  zone           = var.zone
  vpc_network    = module.vpc.vpc_self_link
  subnet_name    = module.vpc.subnet_name
  
  tags = local.common_tags
}

# Load Balancer
module "lb" {
  source = "../../modules/lb"
  
  project_id    = var.project_id
  environment   = local.environment
  lb_name      = "vita-lb-${local.environment}"
  vpc_network  = module.vpc.vpc_self_link
  backend_vms  = [module.vm.instance_self_link]
  
  tags = local.common_tags
}

# Cloud Storage
module "storage" {
  source = "../../modules/storage"
  
  project_id    = var.project_id
  environment   = local.environment
  bucket_prefix = "vita-storage"
  region       = var.region
  
  tags = local.common_tags
}

# Artifact Registry
module "artifact_registry" {
  source = "../../modules/artifact-registry"
  
  project_id    = var.project_id
  environment   = local.environment
  repository_id = "vita-apps"
  region       = var.region
  
  tags = local.common_tags
}

# Firewall Rules
module "firewall" {
  source = "../../modules/firewall"
  
  project_id  = var.project_id
  environment = local.environment
  vpc_network = module.vpc.vpc_name
  
  tags = local.common_tags
}
