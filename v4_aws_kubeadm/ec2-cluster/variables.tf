# Infrastructure Variables
variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "vpn_vpc_cidr" {
  description = "CIDR block for VPN VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gcp_vpc_cidr" {  #GCP VPC CIDR
  description = "CIDR block for GCP VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
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
  description = "AMI ID to use for all instances (Ubuntu 24.04 LTS recommended)"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_storage_size" {
  description = "RDS storage size in GB"
  type        = number
}

variable "db_storage_type" {
  description = "RDS storage type"
  type        = string
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
}

variable "db_username" {
  description = "RDS admin username"
  type        = string
}

variable "db_password" {
  description = "RDS admin password"
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "RDS engine type"
  type        = string
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
}

variable "db_parameter_group_name" {
  description = "RDS parameter group name"
  type        = string
}

variable "db_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "alertmanager_smtp_username" {
  description = "SMTP username for Alertmanager"
  type        = string
}

variable "alertmanager_smtp_password" {
  description = "SMTP password for Alertmanager"
  type        = string
  sensitive   = true
}

variable "alertmanager_email_from" {
  description = "Email from address for Alertmanager"
  type        = string
}

variable "alertmanager_email_to" {
  description = "Email to address for Alertmanager"
  type        = string
}

variable "alertmanager_smtp_host" {
  description = "SMTP host for Alertmanager"
  type        = string
}

variable "alertmanager_smtp_port" {
  description = "SMTP port for Alertmanager"
  type        = number
  default     = 587
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus server"
  type        = string
}

variable "promtail_version" {
  description = "Promtail Helm chart version"
  type        = string
}

variable "loki_version" {
  description = "Loki Distributed Helm chart version"
  type        = string
}

variable "loki_service_account_name" {
  description = "Service account name for Loki"
  type        = string
}

variable "log_bucket_name" {
  description = "S3 bucket name for Loki"
  type        = string
}

variable "prometheus_operator_version" {
  description = "Prometheus Operator Helm chart version"
  type        = string
}

variable "monitoring_data_retention_days" {
  description = "Number of days to keep monitoring data in S3"
  type        = number
}

variable "argocd_namespace" {
  description = "The namespace to install ArgoCD in"
  type        = string
}

variable "argocd_chart_version" {
  description = "The version of the ArgoCD Helm chart to install"
  type        = string
}

variable "argocd_service_type" {
  description = "The service type for the ArgoCD server"
  type        = string
}

variable "argocd_admin_password_bcrypt" {
  description = "Bcrypt hash of the admin password"
  type        = string
  sensitive   = true
}

variable "argocd_server_secret_key" {
  description = "The server secret key for ArgoCD (must be at least 16 characters)"
  type        = string
  sensitive   = true
}

variable "argocd_enable_dex" {
  description = "Enable Dex for SSO"
  type        = bool
}

variable "argocd_insecure" {
  description = "Allow insecure connections to the ArgoCD server"
  type        = bool
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
  description = "Domain name for the Route53 record (e.g., dev.looper.my)"
  type        = string
  default     = ""
}