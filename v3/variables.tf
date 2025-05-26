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

variable "db_zone" {
  description = "GCP zone for database instance"
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

variable "app_machine_type" {
  description = "Application VM Instance Machine type"
  type        = string
}

variable "db_machine_type" {
  description = "Database VM Instance Machine type"
  type        = string
}

variable "disk_image" {
  description = "Instance Disk Image (base OS)"
  type        = string
}

variable "app_disk_size" {
  description = "Application Instance Disk Size(GB)"
  type        = number
}

variable "db_disk_size" {
  description = "Database Instance Disk Size(GB)"
  type        = number
}

variable "gpu_type" {
  description = "Type of GPU to attach to application instances"
  type        = string
  default     = "nvidia-l4"
}

variable "gpu_count" {
  description = "Number of GPUs to attach to application instances"
  type        = number
  default     = 1
}

variable "backup_bucket" {
  description = "GCS bucket name for database backups"
  type        = string
}

variable "backup_schedule" {
  description = "Cron schedule for database backups"
  type        = string
  default     = "0 0 * * *"  # Default: daily at midnight
}

variable "ssl_certificate" {
  description = "SSL certificate resource (can be self-managed or Google-managed)"
  type        = string
  default     = ""
}

variable "create_dns_record" {
  description = "Flag to create a DNS record"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
}

variable "dns_managed_zone" {
  description = "DNS Managed Zone Name (only if create_dns_record == true)"
  type        = string
  default     = ""
}