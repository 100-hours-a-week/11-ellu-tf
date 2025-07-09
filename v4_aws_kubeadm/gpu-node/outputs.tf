output "vpn_gateway_ip" {
  description = "External IP address of the GCP VPN Gateway"
  value       = google_compute_address.vpn_static_ip.address
}

output "gpu_instance_private_ip" {
  description = "Private IP address of the GPU worker node"
  value       = google_compute_instance.gpu_worker_node.network_interface[0].network_ip
}

output "gpu_instance_name" {
  description = "Name of the GPU instance"
  value       = google_compute_instance.gpu_worker_node.name
}

output "vpc_network_name" {
  description = "Name of the GCP VPC network"
  value       = google_compute_network.gpu_vpc.name
}