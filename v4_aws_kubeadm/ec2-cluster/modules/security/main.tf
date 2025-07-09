# kubeadm 클러스터용 보안 그룹
resource "aws_security_group" "k8s_sg" {
  name        = "${var.cluster_name}-k8s-security-group"
  description = "Security group for Kubernetes cluster nodes"
  vpc_id      = var.vpc_id

  # SSH는 VPN을 통해서만 접속 가능하도록 제한
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpn_vpc_cidr]
    description = "SSH access from VPN"
  }

  # 쿠버네티스 API 서버 포트
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpn_vpc_cidr, var.gcp_vpc_cidr] # GCP와 VPN 대역 허용
    description = "Kubernetes API server"
  }

  # etcd 클라이언트 API (마스터 노드 통신)
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.gcp_vpc_cidr] 
    description = "etcd server client API"
  }

  # kubelet API (노드 관리용)
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.gcp_vpc_cidr]  
    description = "Kubelet API"
  }

  # 스케줄러 서비스
  ingress {
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.gcp_vpc_cidr]  
    description = "Kube-scheduler"
  }

  # 컨트롤러 매니저
  ingress {
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.gcp_vpc_cidr]  
    description = "Kube-controller-manager"
  }

  # NodePort 서비스 범위 (30000-32767)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpn_vpc_cidr, var.gcp_vpc_cidr]  # VPN과 GCP만 허용
    description = "NodePort Services"
  }

  # Calico 네트워크 플러그인 - BGP 프로토콜
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.gcp_vpc_cidr]
    description = "Calico BGP"
  }

  # Calico 네트워크 플러그인 - VXLAN 오버레이
  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr, var.gcp_vpc_cidr]
    description = "Calico VXLAN"
  }

  # VPN 클라이언트들 간 통신 허용
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpn_vpc_cidr]
    description = "Allow traffic from OpenVPN clients"
  }

  # GCP GPU 노드와의 통신 허용
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.gcp_vpc_cidr]
    description = "Allow traffic from GCP GPU node"
  }

  # 클러스터 내부 노드 간 통신
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    description = "Internal cluster communication"
  }

  # NLB에서 NGINX 인그레스 컨트롤러 HTTP 포트로
  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NGINX Ingress HTTP NodePort from NLB"
  }

  ingress {
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NGINX Ingress HTTPS NodePort from NLB"
  }

  # 외부 인터넷으로의 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-k8s-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# RDS 데이터베이스 보안 그룹
resource "aws_security_group" "rds_sg" {
  name        = "${var.cluster_name}-rds-security-group"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  # 쿠버네티스 클러스터에서만 DB 접속 허용
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.k8s_subnet_cidrs
    description = "PostgreSQL access from Kubernetes subnets"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

# AWS Secret Manager 접근용 IAM 역할
resource "aws_iam_role" "external_secrets_role" {
  name = "${var.cluster_name}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-external-secrets-role"
  }
}

# Secret Manager 접근 권한 정책
resource "aws_iam_policy" "external_secrets_policy" {
  name        = "${var.cluster_name}-external-secrets-policy"
  description = "Policy for External Secrets Operator to access AWS Secret Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:*:secret:looper/prod*",
          "arn:aws:secretsmanager:${var.region}:*:secret:looper/dev*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-external-secrets-policy"
  }
}

# Secret Manager 역할에 권한 정책 연결
resource "aws_iam_role_policy_attachment" "external_secrets_policy_attachment" {
  role       = aws_iam_role.external_secrets_role.name
  policy_arn = aws_iam_policy.external_secrets_policy.arn
}

# 워커 노드에서 사용할 인스턴스 프로파일
resource "aws_iam_instance_profile" "external_secrets_instance_profile" {
  name = "${var.cluster_name}-external-secrets-instance-profile"
  role = aws_iam_role.external_secrets_role.name

  tags = {
    Name = "${var.cluster_name}-external-secrets-instance-profile"
  }
}

# EBS CSI 드라이버 권한 정책
resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${var.cluster_name}-ebs-csi-policy"
  description = "Policy for EBS CSI Driver to manage EBS volumes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = [
              "CreateVolume",
              "CreateSnapshot"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/ebs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/CSIVolumeName" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/CSIVolumeName" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/kubernetes.io/created-for/pvc/name" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/CSIVolumeSnapshotName" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" = "true"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-ebs-csi-policy"
  }
}

# EBS CSI 드라이버 역할에 권한 정책 연결
resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attachment" {
  role       = aws_iam_role.external_secrets_role.name
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
}