variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "vpn_vpc_cidr" {
  description = "CIDR block for VPN VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gcp_vpc_cidr" {  # NEW: GCP VPC CIDR
  description = "CIDR block for GCP VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "k8s_subnet_cidrs" {
  description = "CIDR blocks for Kubernetes subnets"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

# 개발용 (RDS가 퍼블릭 서브넷 인그레스 추가)
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets where Kubernetes nodes are located"
  type        = list(string)
}