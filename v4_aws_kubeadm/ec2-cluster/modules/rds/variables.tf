variable "private_rds_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "ID of the RDS security group"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
}

variable "db_username" {
  description = "RDS admin username"
  type        = string
}

variable "db_password" {
  description = "RDS admin password"
  type        = string
  sensitive   = true
}

variable "db_storage_type" {
  description = "RDS storage type"
  type        = string
}

variable "db_storage_size" {
  description = "RDS storage size in GB"
  type        = number
  default     = 20
}

variable "db_instance_class"{
  description = "RDS instance class"
  type        = string 
}

variable "db_parameter_group_name" {
  description = "RDS parameter group name"
  type        = string
}

variable "db_engine" {
  description = "RDS engine type"
  type        = string
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
}

variable "db_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
}