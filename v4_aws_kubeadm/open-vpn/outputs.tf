output "openvpn_public_ip" {
  description = "Public IP address of the OpenVPN server"
  value       = aws_eip.openvpn.public_ip
}

output "openvpn_instance_id" {
  description = "Instance ID of the OpenVPN server"
  value       = aws_instance.openvpn.id
}

output "vpn_vpc_id" {
  description = "ID of the VPN VPC"
  value       = aws_vpc.vpn_vpc.id
}

output "vpn_vpc_cidr" {
  description = "CIDR block of the VPN VPC"
  value       = aws_vpc.vpn_vpc.cidr_block
}

output "vpn_public_subnet_ids" {
  description = "IDs of the VPN public subnets"
  value       = aws_subnet.vpn_public[*].id
}

output "vpn_public_route_table_id" {
  description = "ID of the VPN public route table"
  value       = aws_route_table.vpn_public.id
}

output "vpn_security_group_id" {
  description = "ID of the VPN security group"
  value       = aws_security_group.vpn_sg.id
}