variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}