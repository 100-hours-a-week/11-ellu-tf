project_id        = "" //프로젝트 ID
region            = "" // 리전
zones             = ["", ""] //app 서버 가용 영역
db_zone           = "" //db 서버 가용 영역
prefix            = "looper-prod"
subnet_cidr       = "" //서브넷 CIDR

app_machine_type  = "g2-standard-4"
db_machine_type   = "n2-standard-4"
disk_image        = "ubuntu-os-cloud/ubuntu-2204-lts"
app_disk_size     = 50
db_disk_size      = 200
gpu_type          = "nvidia-l4"
gpu_count         = 1

backup_bucket     = "looper-prod-db-backups"
backup_schedule   = "0 0 * * *"  

ssl_certificate   = ""
create_dns_record = false
domain_name       = "looper.my"
dns_managed_zone  = ""