output "instance_group" {
  description = "The unmanaged instance group for the application servers"
  value       = google_compute_instance_group.app_group.self_link
}

output "instance_names" {
  description = "The names of the app server instances"
  value       = [for instance in google_compute_instance.app_server : instance.name]
}

output "instance_internal_ips" {
  description = "The internal IP addresses of the app servers"
  value       = [for addr in google_compute_address.app_internal_ip : addr.address]
}

output "instance_zones" {
  description = "The zones where app servers are deployed"
  value       = [for instance in google_compute_instance.app_server : instance.zone]
}