variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zones" {
  description = "GCP zones for application instances"
  type        = list(string)
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

variable "app_service_account" {
  description = "Service account email for application instances"
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

variable "gpu_type" {
  description = "Type of GPU to attach"
  type        = string
}

variable "gpu_count" {
  description = "Number of GPUs to attach"
  type        = number
}

variable "db_private_ip" {
  description = "Private IP address of the database instance"
  type        = string
}