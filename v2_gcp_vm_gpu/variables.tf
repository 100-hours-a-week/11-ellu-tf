variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for subnet"
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

variable "create_dns_record" {
  description = "Flag to create a DNS record"
  type        = bool
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
}

variable "dns_managed_zone" {
  description = "DNS Manage Zone Name (only if create_dns_record == true)"
  type        = string
}