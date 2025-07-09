terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# GCP VPC 네트워크
resource "google_compute_network" "gpu_vpc" {
  name                    = "gpu-vpc"
  auto_create_subnetworks = false
}

# GCP 서브넷
resource "google_compute_subnetwork" "gpu_subnet" {
  name          = "gpu-subnet"
  ip_cidr_range = "10.2.0.0/24"
  region        = var.region
  network       = google_compute_network.gpu_vpc.id
}

# VPN용 클라우드 라우터
resource "google_compute_router" "gpu_router" {
  name    = "gpu-router"
  region  = var.region
  network = google_compute_network.gpu_vpc.id
}

# 클라우드 VPN 게이트웨이
resource "google_compute_vpn_gateway" "gpu_vpn_gateway" {
  name    = "gpu-vpn-gateway"
  network = google_compute_network.gpu_vpc.id
  region  = var.region
}

# VPN 게이트웨이용 외부 IP
resource "google_compute_address" "vpn_static_ip" {
  name   = "vpn-static-ip"
  region = var.region
}


# VPN 포워딩 규칙들
resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.gpu_vpn_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.gpu_vpn_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.gpu_vpn_gateway.id
}


# 쿠버네티스 방화벽 규칙
resource "google_compute_firewall" "allow_kubernetes" {
  name    = "allow-kubernetes"
  network = google_compute_network.gpu_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6443", "10250", "10251", "10252", "2379", "2380"]
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
    ports    = ["8472"]  # Flannel VXLAN
  }

  source_ranges = ["10.0.0.0/16", "10.1.0.0/16"]  # AWS VPC들
  target_tags   = ["k8s-gpu-node"]
}

# IAP SSH 접근용 방화벽 규칙
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.gpu_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # IAP IP 대역
  target_tags   = ["k8s-gpu-node"]
}

# Calico 방화벽 규칙
resource "google_compute_firewall" "allow_calico" {
  name    = "allow-calico"
  network = google_compute_network.gpu_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["179"]  # BGP
  }

  allow {
    protocol = "udp"
    ports    = ["4789"]  # VXLAN
  }

  source_ranges = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
  target_tags   = ["k8s-gpu-node"]
}

# 내부 통신용 방화벽 규칙
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.gpu_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.2.0.0/16"]  # GCP VPC 내부
  target_tags   = ["k8s-gpu-node"]
}

# NVIDIA L4 GPU 인스턴스
resource "google_compute_instance" "gpu_worker_node" {
  name         = "k8s-gpu-worker"
  machine_type = "g2-standard-4"  # NVIDIA L4 인스턴스 타입
  zone         = var.zone

  tags = ["k8s-gpu-node"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  # NVIDIA L4 GPU 연결
  guest_accelerator {
    type  = "nvidia-l4"
    count = 1
  }

  scheduling {
    # GPU 인스턴스는 on_host_maintenance = "TERMINATE" 필요
    on_host_maintenance = "TERMINATE"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gpu_subnet.id
    # 외부 IP 없음 - 프라이빗 전용
  }

  # IAP/콘솔 SSH용 OS 로그인 활성화
  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/gpu-node-init.sh")

  service_account {
    scopes = ["cloud-platform"]
  }
}

# 아웃바운드 인터넷 접근용 Cloud NAT
resource "google_compute_router_nat" "gpu_nat" {
  name   = "gpu-nat"
  router = google_compute_router.gpu_router.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "allow_aws_to_ai_summary" {
  name    = "allow-aws-to-ai-summary"
  network = google_compute_network.gpu_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8000"]  # ai-summary와 chromadb
  }

  source_ranges = ["10.1.0.0/16"]  # AWS VPC
  target_tags   = ["k8s-gpu-node"]
}

#----------------------------------------------------------------------
# AWS로의 VPN 터널 (터널 1)
resource "google_compute_vpn_tunnel" "tunnel1" {
  name          = "tunnel1-to-aws"
  peer_ip       = var.aws_vpn_tunnel1_address
  shared_secret = var.aws_vpn_tunnel1_preshared_key

  target_vpn_gateway = google_compute_vpn_gateway.gpu_vpn_gateway.id

  # 커스텀 서브넷 모드에 필요
  local_traffic_selector  = ["10.2.0.0/16"]  # GCP VPC CIDR
  remote_traffic_selector = ["10.0.0.0/16", "10.1.0.0/16", "10.96.0.0/16","192.168.0.0/16"]

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

# AWS로의 VPN 터널 (터널 2)
resource "google_compute_vpn_tunnel" "tunnel2" {
  name          = "tunnel2-to-aws"
  peer_ip       = var.aws_vpn_tunnel2_address
  shared_secret = var.aws_vpn_tunnel2_preshared_key

  target_vpn_gateway = google_compute_vpn_gateway.gpu_vpn_gateway.id

  local_traffic_selector  = ["10.2.0.0/16"]  # GCP VPC CIDR
  remote_traffic_selector = ["10.0.0.0/16", "10.1.0.0/16", "10.96.0.0/16","192.168.0.0/16"]

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

# AWS K8s VPC로의 라우트
resource "google_compute_route" "route_to_aws_k8s" {
  name       = "route-to-aws-k8s"
  dest_range = "10.1.0.0/16"  # AWS K8s VPC CIDR
  network    = google_compute_network.gpu_vpc.name
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
  priority   = 1000
}

# AWS VPN VPC로의 라우트
resource "google_compute_route" "route_to_aws_vpn" {
  name       = "route-to-aws-vpn"
  dest_range = "10.0.0.0/16"  # AWS VPN VPC CIDR
  network    = google_compute_network.gpu_vpc.name
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
  priority   = 1000
}