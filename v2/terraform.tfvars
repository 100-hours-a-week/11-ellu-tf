project_id        = "" ## 프로젝트 ID
region            = "asia-northeast3"
zone              = "asia-northeast3-a"
prefix            = "looper-prod"
subnet_cidr       = "10.0.0.0/24"

machine_type      = "g2-standard-4" 
disk_image        = "ubuntu-os-cloud/ubuntu-2404-lts"
disk_size         = 50
create_dns_record = false
domain_name       = "looper.my"