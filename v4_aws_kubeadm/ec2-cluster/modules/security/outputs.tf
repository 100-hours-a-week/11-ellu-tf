output "k8s_security_group_id" {
  description = "ID of the Kubernetes cluster security group"
  value       = aws_security_group.k8s_sg.id
}

output "rds_sg_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds_sg.id
}

output "external_secrets_instance_profile_name" {
  description = "Name of the instance profile for External Secrets Operator"
  value       = aws_iam_instance_profile.external_secrets_instance_profile.name
}