variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets where worker nodes will be placed"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for the instances"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
}

variable "control_plane_instance_type" {
  description = "Instance type for the Kubernetes control plane"
  type        = string
}

variable "worker_instance_type" {
  description = "Instance type for the Kubernetes worker nodes"
  type        = string
}

variable "kafka_instance_type" {
  description = "Instance type for the Kafka node"
  type        = string
}

variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
}

variable "ami_id" {
  description = "AMI ID to use for all instances"
  type        = string
}

variable "external_secrets_instance_profile_name" {
  description = "Name of the IAM instance profile for External Secrets Operator"
  type        = string
}