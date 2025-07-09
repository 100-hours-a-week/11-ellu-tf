# 컨트롤 플레인
resource "aws_instance" "control_plane" {
  ami                    = var.ami_id
  instance_type          = var.control_plane_instance_type
  subnet_id              = var.private_subnet_ids[0]  #프라이빗 서브넷 사용
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  associate_public_ip_address = false 
  iam_instance_profile        = var.external_secrets_instance_profile_name

  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/scripts/control-plane-init.sh", {
    private_ip = ""  
  })

  tags = {
    Name = "${var.cluster_name}-control-plane"
    Role = "control-plane"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# 워커 노드
resource "aws_instance" "workers" {
  count                  = var.worker_count
  ami                    = var.ami_id
  instance_type          = var.worker_instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]  #프라이빗 서브넷 사용
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  associate_public_ip_address = false  
  iam_instance_profile        = var.external_secrets_instance_profile_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = file("${path.module}/scripts/worker-init.sh")

  tags = {
    Name = "${var.cluster_name}-worker-${count.index + 1}"
    Role = "worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Kafka 전용 노드
resource "aws_instance" "kafka_node" {
  ami                    = var.ami_id
  instance_type          = var.kafka_instance_type
  subnet_id              = var.private_subnet_ids[0]  
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  associate_public_ip_address = false  
  iam_instance_profile        = var.external_secrets_instance_profile_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = file("${path.module}/scripts/worker-init.sh")

  tags = {
    Name = "${var.cluster_name}-kafka-node"
    Role = "kafka"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# 로드 밸런서용 보안 그룹
resource "aws_security_group" "lb_sg" {
  name        = "${var.cluster_name}-lb-sg"
  description = "Security group for Kubernetes load balancers"
  vpc_id      = data.aws_subnet.private.vpc_id  

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort services"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-lb-sg"
  }
}

# 프라이빗 서브넷 데이터 소스
data "aws_subnet" "private" {
  id = var.private_subnet_ids[0]
}