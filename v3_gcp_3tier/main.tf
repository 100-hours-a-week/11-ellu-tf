provider "google" {
  project     = var.project_id
  region      = var.region
}

module "network" {
  source      = "./modules/network"
  project_id  = var.project_id
  region      = var.region
  prefix      = var.prefix
  subnet_cidr = var.subnet_cidr
}

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  prefix     = var.prefix
  
  depends_on = [module.network]
}

module "database" {
  source                = "./modules/database"
  project_id            = var.project_id
  region                = var.region
  zone                  = var.db_zone
  prefix                = var.prefix
  network_self_link     = module.network.vpc_self_link
  subnet_self_link      = module.network.subnet_self_link
  db_service_account    = module.iam.db_service_account_email
  machine_type          = var.db_machine_type
  disk_image            = var.disk_image
  disk_size             = var.db_disk_size
  backup_bucket         = var.backup_bucket
  backup_schedule       = var.backup_schedule
  
  depends_on = [module.iam, module.network]
}

module "application" {
  source                = "./modules/application"
  project_id            = var.project_id
  region                = var.region
  zones                 = var.zones
  prefix                = var.prefix
  network_self_link     = module.network.vpc_self_link
  subnet_self_link      = module.network.subnet_self_link
  app_service_account   = module.iam.app_service_account_email
  machine_type          = var.app_machine_type
  disk_image            = var.disk_image
  disk_size             = var.app_disk_size
  gpu_type              = var.gpu_type
  gpu_count             = var.gpu_count
  db_private_ip         = module.database.db_private_ip
  
  depends_on = [module.database, module.iam, module.network]
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  project_id          = var.project_id
  region              = var.region
  prefix              = var.prefix
  backend_instance_group = module.application.instance_group
  ssl_certificate     = var.ssl_certificate
  domain_name         = var.domain_name
  create_dns_record   = var.create_dns_record
  dns_managed_zone    = var.dns_managed_zone
  
  depends_on = [module.application, module.network]
}