output "instance_name" {
  description = "Name of the database VM instance"
  value       = google_compute_instance.db_server.name
}

output "db_private_ip" {
  description = "The private IP address of the database instance"
  value       = google_compute_address.db_internal_ip.address
}

output "backup_bucket_url" {
  description = "The GCS bucket URL for database backups"
  value       = "gs://${google_storage_bucket.db_backup_bucket.name}"
}