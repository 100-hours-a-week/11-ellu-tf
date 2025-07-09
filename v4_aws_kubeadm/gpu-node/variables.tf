variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast3"  # Seoul region
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-northeast3-a"  # Seoul zone with GPU support
}

# AWS VPN Connection details (from AWS terraform outputs)
variable "aws_vpn_tunnel1_address" {
  description = "AWS VPN tunnel 1 public IP address"
  type        = string
}

variable "aws_vpn_tunnel2_address" {
  description = "AWS VPN tunnel 2 public IP address"
  type        = string
}

variable "aws_vpn_tunnel1_preshared_key" {
  description = "AWS VPN tunnel 1 preshared key"
  type        = string
  sensitive   = true
}

variable "aws_vpn_tunnel2_preshared_key" {
  description = "AWS VPN tunnel 2 preshared key"
  type        = string
  sensitive   = true
}