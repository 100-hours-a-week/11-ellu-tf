output "instance_group" {
  description = "The instance group for the application servers"
  value       = google_compute_region_instance_group_manager.app_group.instance_group
}

output "instance_names" {
  description = "The base name for the instances"
  value       = "${var.prefix}-app"
}