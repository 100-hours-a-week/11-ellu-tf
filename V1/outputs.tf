output "public_ip" {
  description = "The public IP address"
  value       = google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "The internal IP address"
  value       = google_compute_instance.app_server.network_interface[0].network_ip
}
