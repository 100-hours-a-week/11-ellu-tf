output "app_service_account_email" {
  description = "The email of the application service account"
  value       = google_service_account.app_service_account.email
}

output "db_service_account_email" {
  description = "The email of the database service account"
  value       = google_service_account.db_service_account.email
}