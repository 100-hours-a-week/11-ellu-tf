variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone for database instance"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "network_self_link" {
  description = "Self link of the VPC network"
  type        = string
}

variable "subnet_self_link" {
  description = "Self link of the subnet"
  type        = string
}

variable "db_service_account" {
  description = "Service account email for database instance"
  type        = string
}

variable "machine_type" {
  description = "VM Instance Machine type"
  type        = string
}

variable "disk_image" {
  description = "Instance Disk Image (base OS)"
  type        = string
}

variable "disk_size" {
  description = "Instance Disk Size(GB)"
  type        = number
}

variable "backup_bucket" {
  description = "GCS bucket name for database backups"
  type        = string
}

variable "backup_schedule" {
  description = "Cron schedule for database backups"
  type        = string
}