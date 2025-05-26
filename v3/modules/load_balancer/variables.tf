variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "backend_instance_group" {
  description = "Self link of the backend instance group"
  type        = string
}

variable "ssl_certificate" {
  description = "Self link of an existing SSL certificate (leave empty to create a new one)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain Name for SSL certificate and DNS record"
  type        = string
}

variable "create_dns_record" {
  description = "Flag to create a DNS record"
  type        = bool
  default     = false
}

variable "dns_managed_zone" {
  description = "DNS Managed Zone Name (only if create_dns_record == true)"
  type        = string
  default     = ""
}