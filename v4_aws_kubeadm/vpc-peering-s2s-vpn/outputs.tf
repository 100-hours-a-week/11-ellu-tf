output "vpc_peering_connection_id" {
  description = "ID of the VPC Peering Connection between VPN and K8s VPCs"
  value       = aws_vpc_peering_connection.vpn_to_k8s.id
}

output "k8s_vpc_id" {
  description = "ID of the K8s VPC"
  value       = data.aws_vpc.k8s_vpc.id
}

output "vpn_vpc_id" {
  description = "ID of the VPN VPC"
  value       = data.aws_vpc.vpn_vpc.id
}

output "k8s_private_subnet_ids" {
  description = "IDs of the K8s private subnets"
  value       = data.aws_subnets.k8s_private_subnets.ids
}

output "vpn_private_subnet_ids" {
  description = "IDs of the VPN private subnets"
  value       = data.aws_subnets.vpn_private_subnets.ids
}

# VPN Connection outputs for GCP connection
output "vpn_connection_id" {
  description = "ID of the VPN Connection to GCP"
  value       = aws_vpn_connection.gcp_vpn.id
}

output "vpn_connection_tunnel1_address" {
  description = "Public IP address of VPN tunnel 1"
  value       = aws_vpn_connection.gcp_vpn.tunnel1_address
}

output "vpn_connection_tunnel2_address" {
  description = "Public IP address of VPN tunnel 2"
  value       = aws_vpn_connection.gcp_vpn.tunnel2_address
}

output "vpn_connection_tunnel1_preshared_key" {
  description = "Preshared key for VPN tunnel 1"
  value       = aws_vpn_connection.gcp_vpn.tunnel1_preshared_key
  sensitive   = true
}

output "vpn_connection_tunnel2_preshared_key" {
  description = "Preshared key for VPN tunnel 2"
  value       = aws_vpn_connection.gcp_vpn.tunnel2_preshared_key
  sensitive   = true
}

output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = aws_vpn_gateway.gcp_vpn_gateway.id
}

output "customer_gateway_id" {
  description = "ID of the Customer Gateway for GCP"
  value       = aws_customer_gateway.gcp_customer_gateway.id
}