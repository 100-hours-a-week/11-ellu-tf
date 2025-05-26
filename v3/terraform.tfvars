project_id        = "" ##프로젝트 id
region            = "asia-northeast3"
zones             = ["asia-northeast3-a", "asia-northeast3-b"]
db_zone           = "asia-northeast3-a"
prefix            = "looper-prod"
subnet_cidr       = "10.0.0.0/24"

app_machine_type  = "g2-standard-4"
db_machine_type   = "n2-standard-4"
disk_image        = "ubuntu-os-cloud/ubuntu-2404-lts"
app_disk_size     = 50
db_disk_size      = 200
gpu_type          = "nvidia-l4"
gpu_count         = 1

backup_bucket     = "looper-prod-db-backups"
backup_schedule   = "0 0 * * *"  

ssl_certificate   = ""
create_dns_record = false
domain_name       = "dev.looper.my"
dns_managed_zone  = "example-zone"