variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the NLB"
  type        = list(string)
}

variable "worker_instance_ids" {
  description = "List of worker node instance IDs"
  type        = list(string)
}

variable "nginx_http_nodeport" {
  description = "NodePort for NGINX Ingress HTTP service"
  type        = number
  default     = 30080
}

variable "nginx_https_nodeport" {
  description = "NodePort for NGINX Ingress HTTPS service"
  type        = number
  default     = 30443
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listener"
  type        = string
}

variable "create_route53_record" {
  description = "Whether to create a Route53 record for the NLB"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (required if create_route53_record is true)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the Route53 record (required if create_route53_record is true)"
  type        = string
  default     = ""
}