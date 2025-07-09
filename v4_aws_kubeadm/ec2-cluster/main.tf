terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  cluster_name        = var.cluster_name
}

module "security" {
  source = "./modules/security"
  
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  cluster_name        = var.cluster_name
  vpn_vpc_cidr        = var.vpn_vpc_cidr
  gcp_vpc_cidr        = var.gcp_vpc_cidr  # NEW: GCP CIDR 전달
  k8s_subnet_cidrs    = module.vpc.private_k8s_subnet_cidrs
  public_subnet_cidrs = module.vpc.public_subnet_cidrs
  region              = var.region

  depends_on = [module.vpc]
}

module "kubernetes" {
  source = "./modules/kubernetes"
  
  cluster_name                = var.cluster_name
  availability_zones          = var.availability_zones
  public_subnet_ids           = module.vpc.public_subnet_ids
  private_subnet_ids          = module.vpc.private_k8s_subnet_ids
  security_group_id           = module.security.k8s_security_group_id
  key_name                    = var.key_name
  control_plane_instance_type = var.control_plane_instance_type
  worker_instance_type        = var.worker_instance_type
  kafka_instance_type         = var.kafka_instance_type
  worker_count                = var.worker_count
  ami_id                      = var.ami_id
  external_secrets_instance_profile_name = module.security.external_secrets_instance_profile_name

  depends_on = [module.vpc, module.security]
}

module "rds" {
  source = "./modules/rds"
  
  private_rds_subnet_ids      = module.vpc.private_rds_subnet_ids
  rds_security_group_id       = module.security.rds_sg_id
  availability_zones          = var.availability_zones
  db_name                     = var.db_name
  db_engine                   = var.db_engine
  db_engine_version           = var.db_engine_version
  db_username                 = var.db_username
  db_password                 = var.db_password
  db_parameter_group_name     = var.db_parameter_group_name
  db_instance_class           = var.db_instance_class
  db_backup_retention_period  = var.db_backup_retention_period
  db_storage_size             = var.db_storage_size
  db_storage_type             = var.db_storage_type

  depends_on = [module.vpc, module.security]
}

module "nlb" {
  source = "./modules/nlb"
  
  cluster_name         = var.cluster_name
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  worker_instance_ids  = module.kubernetes.worker_instance_ids
  nginx_http_nodeport  = var.nginx_http_nodeport
  nginx_https_nodeport = var.nginx_https_nodeport
  acm_certificate_arn  = var.acm_certificate_arn
  
  # Route53 (create 값 true 설정시 트리거)
  create_route53_record = var.create_route53_record
  route53_zone_id      = var.route53_zone_id
  domain_name          = var.domain_name
  
  depends_on = [module.kubernetes]
}