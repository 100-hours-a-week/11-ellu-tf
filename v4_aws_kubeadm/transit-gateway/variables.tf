variable "k8s_vpc_name" { 
  description = "Name tag of the K8s VPC"
  type        = string
  default     = "k8s-vpc"
}

variable "vpn_vpc_name" {
  description = "Name tag of the VPN VPC"
  type        = string
  default     = "vpn-vpc"
}

variable "k8s_vpc_cidr" {
  description = "CIDR block of the K8s VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "vpn_vpc_cidr" {
  description = "CIDR block of the VPN VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gcp_vpc_cidr" {
  description = "CIDR block of the GCP VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "gcp_vpn_gateway_ip" {
  description = "Public IP address of the GCP VPN Gateway"
  type        = string
}