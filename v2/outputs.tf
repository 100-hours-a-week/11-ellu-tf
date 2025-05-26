output "public_ip" {
  description = "The public IP address"
  value       = google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "The internal IP address"
  value       = google_compute_instance.app_server.network_interface[0].network_ip
}

output "instance_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.app_server.name
}

output "service_account_email" {
  description = "The email of the service account"
  value       = google_service_account.app_service_account.email
}

output "gpu_type" {
  description = "The type of GPU attached"
  value       = "NVIDIA L4"
}

output "gpu_driver_status" {
  description = "Instructions to check GPU driver status"
  value       = "SSH into the instance and run: 'nvidia-smi' to verify GPU is working properly"
}