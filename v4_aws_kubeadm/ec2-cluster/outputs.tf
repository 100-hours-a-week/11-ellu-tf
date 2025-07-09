output "control_plane_public_ip" {
  description = "Public IP address of the Kubernetes control plane node"
  value       = module.kubernetes.control_plane_public_ip
}

output "control_plane_private_ip" {
  description = "Private IP address of the Kubernetes control plane node"
  value       = module.kubernetes.control_plane_private_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of the Kubernetes worker nodes"
  value       = module.kubernetes.worker_public_ips
}

output "worker_private_ips" {
  description = "Private IP addresses of the Kubernetes worker nodes"
  value       = module.kubernetes.worker_private_ips
}

output "kafka_node_public_ip" {
  description = "Public IP address of the Kafka node"
  value       = module.kubernetes.kafka_node_public_ip
}

output "kafka_node_private_ip" {
  description = "Private IP address of the Kafka node"
  value       = module.kubernetes.kafka_node_private_ip
}

output "rds_primary_endpoint" {
  description = "Primary RDS instance endpoint"
  value       = module.rds.rds_primary_endpoint
}

# output "rds_replica_endpoint" {
#   description = "Replica RDS instance endpoint"
#   value       = module.rds.rds_replica_endpoint
# }

output "cluster_setup_instructions" {
  description = "kubeadm 클러스터 설정 안내"
  value = <<-EOT
    
    🚀 KUBERNETES 클러스터 설정 안내 
    ==========================================

    해당 명령어들은 작성자(김범수/Brian)의 로컬 환경에서 실행되는 명령어들입니다.
    나열된 명령어가 실제 목적에 맞게 작동하지 않을 수 있으며, 키 생성, path directory, IP 주소 등, kubectl 명령어들을 작성자의 환경에 맞게 수정해야 합니다.
    
    1. Control Plane node ssh 접속:
       ssh -i ./.ssh/${var.key_name}.pem ubuntu@${module.kubernetes.control_plane_public_ip}

    2. Worker node ssh 접속 :
        worker nodes
       ${join("\n       ", [for ip in module.kubernetes.worker_public_ips : "ssh -i ./.ssh/${var.key_name}.pem ubuntu@${ip}"])}

       ==========================================
        kafka node
        ssh -i ./.ssh/${var.key_name}.pem ubuntu@${module.kubernetes.kafka_node_public_ip}

    3. Control Plane 초기화:
        sudo kubeadm config images pull

        sudo kubeadm init

        mkdir -p "$HOME"/.kube
        sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
        sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

        # 네트워크 플러그인 = calico
        kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
    
    4. kubeadm token 발행:
        kubeadm token create --print-join-command
    
    5. Worder Nodes 초기화:
        sudo kubeadm reset pre-flight checks

    6. 4번의 출력값을 복사후 sudo 권한으로 worker node에서 실행
       
    7. Control Plane node에서 kubectl 명령어 실행:
        kubectl get nodes
    
    8. Worker nodes role 추가:
        kubectl label node <ip-10-1-0-0> node-role.kubernetes.io/worker=reserved
        kubectl label node <ip-10-1-0-0> node-role.kubernetes.io/worker=reserved
        kubectl label node <ip-10-1-0-0> node-role.kubernetes.io/kafka=reserved
    9. Kafka worker node taint 추가:
        kubectl taint node <ip-10-1-0-0> node-role.kubernetes.io/kafka=reserved:NoSchedule
    📝 DB 주소:
    - Primary RDS: ${module.rds.rds_primary_endpoint}
    
  EOT
}

output "ssh_commands" {
  description = "SSH commands for easy access"
  value = {
    control_plane = "ssh -i ${var.key_name}.pem ubuntu@${module.kubernetes.control_plane_public_ip}"
    workers = [for ip in module.kubernetes.worker_public_ips : "ssh -i ${var.key_name}.pem ubuntu@${ip}"]
  }
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = module.nlb.nlb_dns_name
}

output "nlb_configuration" {
  description = "NLB configuration details"
  value = {
    dns_name     = module.nlb.nlb_dns_name
    zone_id      = module.nlb.nlb_zone_id
    http_nodeport  = var.nginx_http_nodeport
    https_nodeport = var.nginx_https_nodeport
  }
}