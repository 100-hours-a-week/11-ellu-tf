provider "aws" {
  region = "ap-northeast-2" 
}

# 이름 태그로 K8s VPC 찾기
data "aws_vpc" "k8s_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.k8s_vpc_name]
  }
}

# 이름 태그로 VPN VPC 찾기
data "aws_vpc" "vpn_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpn_vpc_name]
  }
}

# K8s 프라이빗 서브넷 찾기
data "aws_subnets" "k8s_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.k8s_vpc.id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["*private-k8s-subnet*"]
  }
}

# VPN 프라이빗 서브넷 찾기
data "aws_subnets" "vpn_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpn_vpc.id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["vpn-private-subnet-*"]
  }
}

# OpenVPN과 K8s VPC 간의 VPC 피어링 연결
resource "aws_vpc_peering_connection" "vpn_to_k8s" {
  vpc_id        = data.aws_vpc.vpn_vpc.id
  peer_vpc_id   = data.aws_vpc.k8s_vpc.id
  auto_accept   = true
  
  tags = {
    Name = "vpn-to-k8s-peering"
  }
}

# GCP용 고객 게이트웨이
resource "aws_customer_gateway" "gcp_customer_gateway" {
  bgp_asn    = 65000
  ip_address = var.gcp_vpn_gateway_ip
  type       = "ipsec.1"
  
  tags = {
    Name = "gcp-customer-gateway"
  }
}

# VPN 게이트웨이 (K8s VPC에 연결)
resource "aws_vpn_gateway" "gcp_vpn_gateway" {
  vpc_id = data.aws_vpc.k8s_vpc.id
  
  tags = {
    Name = "gcp-vpn-gateway"
  }
}

# GCP로의 VPN 연결 (K8s VPC에 직접 연결)
resource "aws_vpn_connection" "gcp_vpn" {
  customer_gateway_id = aws_customer_gateway.gcp_customer_gateway.id
  vpn_gateway_id      = aws_vpn_gateway.gcp_vpn_gateway.id
  type                = "ipsec.1"
  static_routes_only  = true
  
  tags = {
    Name = "gcp-vpn-connection"
  }
}

# VPN 연결용 정적 경로
resource "aws_vpn_connection_route" "to_gcp" {
  vpn_connection_id      = aws_vpn_connection.gcp_vpn.id
  destination_cidr_block = var.gcp_vpc_cidr
}

# K8s VPC에서 라우트 전파 활성화
resource "aws_vpn_gateway_route_propagation" "k8s_propagation" {
  count          = length(data.aws_route_tables.k8s_route_tables.ids)
  vpn_gateway_id = aws_vpn_gateway.gcp_vpn_gateway.id
  route_table_id = data.aws_route_tables.k8s_route_tables.ids[count.index]
}

# K8s VPC 라우트 테이블 가져오기
data "aws_route_tables" "k8s_route_tables" {
  vpc_id = data.aws_vpc.k8s_vpc.id
}

# VPN VPC 라우트 테이블 가져오기
data "aws_route_tables" "vpn_route_tables" {
  vpc_id = data.aws_vpc.vpn_vpc.id
}

# K8s VPC에서 VPN VPC로의 라우트 추가 (VPC 피어링을 통해)
resource "aws_route" "k8s_to_vpn" {
  count                     = length(data.aws_route_tables.k8s_route_tables.ids)
  route_table_id            = data.aws_route_tables.k8s_route_tables.ids[count.index]
  destination_cidr_block    = var.vpn_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpn_to_k8s.id
}

# VPN VPC에서 K8s VPC로의 라우트 추가 (VPC 피어링을 통해)
resource "aws_route" "vpn_to_k8s" {
  count                     = length(data.aws_route_tables.vpn_route_tables.ids)
  route_table_id            = data.aws_route_tables.vpn_route_tables.ids[count.index]
  destination_cidr_block    = var.k8s_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpn_to_k8s.id
}

# VPN VPC에서 GCP VPC로의 라우트 추가 (K8s VPC와 VPN 게이트웨이를 통해)
resource "aws_route" "vpn_to_gcp" {
  count                     = length(data.aws_route_tables.vpn_route_tables.ids)
  route_table_id            = data.aws_route_tables.vpn_route_tables.ids[count.index]
  destination_cidr_block    = var.gcp_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpn_to_k8s.id
}