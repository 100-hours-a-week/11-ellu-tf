terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# OpenVPN VPC
resource "aws_vpc" "vpn_vpc" {
  cidr_block           = var.vpn_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpn-vpc"
  }
}

# VPN VPC용 인터넷 게이트웨이
resource "aws_internet_gateway" "vpn_igw" {
  vpc_id = aws_vpc.vpn_vpc.id

  tags = {
    Name = "vpn-igw"
  }
}

# OpenVPN 서버용 퍼블릭 서브넷
resource "aws_subnet" "vpn_public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpn_vpc.id
  cidr_block              = cidrsubnet(var.vpn_vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpn-public-subnet-${count.index + 1}"
  }
}

# 퍼블릭 서브넷용 라우트 테이블
resource "aws_route_table" "vpn_public" {
  vpc_id = aws_vpc.vpn_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn_igw.id
  }

  # K8s와 GCP VPC로의 라우트는 vpc-peering 모듈에서 추가됨

  tags = {
    Name = "vpn-public-route-table"
  }
}

# 퍼블릭 서브넷용 라우트 테이블 연결
resource "aws_route_table_association" "vpn_public" {
  count          = length(aws_subnet.vpn_public)
  subnet_id      = aws_subnet.vpn_public[count.index].id
  route_table_id = aws_route_table.vpn_public.id
}

# OpenVPN 서버용 보안 그룹
resource "aws_security_group" "vpn_sg" {
  name        = "vpn-security-group"
  description = "Security group for OpenVPN server"
  vpc_id      = aws_vpc.vpn_vpc.id

  # SSH 접근 (프로덕션에서는 제한 필요)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: 오피스/홈 IP로 제한
    description = "SSH access"
  }

  # OpenVPN UDP
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN UDP"
  }

  # OpenVPN 웹 관리 인터페이스
  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: 관리자 IP로 제한
    description = "OpenVPN Admin Web Interface"
  }

  # OpenVPN 웹 관리용 HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: 관리자 IP로 제한
    description = "HTTPS for OpenVPN Admin"
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "vpn-security-group"
  }
}

# OpenVPN 액세스 서버용 EC2 인스턴스
resource "aws_instance" "openvpn" {
  ami                    = var.openvpn_ami
  instance_type          = "t2.small"
  subnet_id              = aws_subnet.vpn_public[0].id
  vpc_security_group_ids = [aws_security_group.vpn_sg.id]
  key_name               = var.key_name
  
  user_data = file("${path.module}/openvpn-setup.sh")
  
  tags = {
    Name = "openvpn-server"
  }
}

# OpenVPN 서버용 탄력적 IP
resource "aws_eip" "openvpn" {
  domain   = "vpc"
  instance = aws_instance.openvpn.id
  
  tags = {
    Name = "openvpn-eip"
  }
}