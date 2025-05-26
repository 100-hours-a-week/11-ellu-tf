output "load_balancer_ip" {
  description = "The public IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "https_url" {
  description = "HTTPS URL to access the load balancer"
  value       = "https://${var.domain_name}"
}

output "ssl_certificate_id" {
  description = "The ID of the SSL certificate"
  value       = var.ssl_certificate != "" ? var.ssl_certificate : (length(google_compute_managed_ssl_certificate.ssl_cert) > 0 ? google_compute_managed_ssl_certificate.ssl_cert[0].id : "None")
}