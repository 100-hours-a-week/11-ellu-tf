output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_k8s_subnet_ids" {
  description = "The IDs of the private Kubernetes subnets"
  value       = aws_subnet.private_k8s[*].id
}

output "private_rds_subnet_ids" {
  description = "The IDs of the private RDS subnets"
  value       = aws_subnet.private_rds[*].id
}

output "private_subnet_ids" {
  description = "All private subnet IDs (both Kubernetes and RDS)"
  value       = concat(aws_subnet.private_k8s[*].id, aws_subnet.private_rds[*].id)
}

output "private_k8s_subnet_cidrs" {
  description = "The CIDR blocks of the private Kubernetes subnets"
  value       = aws_subnet.private_k8s[*].cidr_block
}

output "public_subnet_cidrs" {
  description = "The CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_rds_subnet_cidrs" {
  description = "The CIDR blocks of the private RDS subnets"
  value       = aws_subnet.private_rds[*].cidr_block
}