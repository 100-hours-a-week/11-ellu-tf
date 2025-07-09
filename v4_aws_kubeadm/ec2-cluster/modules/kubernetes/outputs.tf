output "control_plane_public_ip" {
  description = "Public IP address of the Kubernetes control plane node"
  value       = aws_instance.control_plane.public_ip
}

output "control_plane_private_ip" {
  description = "Private IP address of the Kubernetes control plane node"
  value       = aws_instance.control_plane.private_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of the Kubernetes worker nodes (empty for private workers)"
  value       = aws_instance.workers[*].public_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of the Kubernetes worker nodes"
  value       = aws_instance.workers[*].private_ip
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = "https://${aws_instance.control_plane.private_ip}:6443"
}

output "lb_security_group_id" {
  description = "Security group ID for load balancers"
  value       = aws_security_group.lb_sg.id
}

output "worker_instance_ids" {
  description = "Instance IDs of the Kubernetes worker nodes"
  value       = aws_instance.workers[*].id
}

output "kafka_node_public_ip" {
  description = "Public IP address of the Kafka node"
  value       = aws_instance.kafka_node.public_ip
}

output "kafka_node_private_ip" {
  description = "Private IP address of the Kafka node"
  value       = aws_instance.kafka_node.private_ip
}