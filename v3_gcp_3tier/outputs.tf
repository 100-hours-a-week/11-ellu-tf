output "load_balancer_ip" {
  description = "The public IP address of the load balancer"
  value       = module.load_balancer.load_balancer_ip
}

output "application_instance_names" {
  description = "Names of the application VM instances"
  value       = module.application.instance_names
}

output "application_internal_ips" {
  description = "Internal IP addresses of the application instances"
  value       = module.application.instance_internal_ips
}

output "application_zones" {
  description = "Zones where application instances are deployed"
  value       = module.application.instance_zones
}

output "database_instance_name" {
  description = "Name of the database VM instance"
  value       = module.database.instance_name
}

output "database_private_ip" {
  description = "The private IP address of the database instance"
  value       = module.database.db_private_ip
}

output "app_service_account" {
  description = "The email of the application service account"
  value       = module.iam.app_service_account_email
}

output "db_service_account" {
  description = "The email of the database service account"
  value       = module.iam.db_service_account_email
}

output "gpu_type" {
  description = "The type of GPU attached to application instances"
  value       = var.gpu_type
}

output "gpu_driver_status" {
  description = "Instructions to check GPU driver status"
  value       = "SSH into an app instance and run: 'nvidia-smi' to verify GPU is working properly"
}

output "backup_schedule" {
  description = "The schedule for database backups"
  value       = var.backup_schedule
}

output "backup_bucket" {
  description = "The GCS bucket for database backups"
  value       = var.backup_bucket
}

output "ssh_instructions" {
  description = "How to SSH into instances"
  value       = "Use 'gcloud compute ssh [instance-name] --zone [zone] --tunnel-through-iap' since instances have no external IP"
}