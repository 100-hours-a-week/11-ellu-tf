# NLB (워커 노드 타겟)
resource "aws_lb" "nlb" {
  name               = "${var.cluster_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids
  
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
  
  tags = {
    Name = "${var.cluster_name}-nlb"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# HTTP(80) 타겟 그룹
resource "aws_lb_target_group" "http" {
  name     = "${var.cluster_name}-http-tg"
  port     = var.nginx_http_nodeport
  protocol = "TCP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = var.nginx_http_nodeport
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  deregistration_delay = 10
  
  tags = {
    Name = "${var.cluster_name}-http-tg"
  }
}

# HTTPS(443) 타겟 그룹
resource "aws_lb_target_group" "https" {
  name     = "${var.cluster_name}-https-tg"
  port     = var.nginx_https_nodeport
  protocol = "TCP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = var.nginx_https_nodeport
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  deregistration_delay = 10
  
  tags = {
    Name = "${var.cluster_name}-https-tg"
  }
}

# 워커 노드 <-> HTTP 타겟 그룹 결합
resource "aws_lb_target_group_attachment" "http" {
  count            = length(var.worker_instance_ids)
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = var.worker_instance_ids[count.index]
  port             = var.nginx_http_nodeport
}

# 워커 노드 <-> HTTPS 타겟 그룹 결합
resource "aws_lb_target_group_attachment" "https" {
  count            = length(var.worker_instance_ids)
  target_group_arn = aws_lb_target_group.https.arn
  target_id        = var.worker_instance_ids[count.index]
  port             = var.nginx_https_nodeport
}

# HTTPS 리스너 (TLS 종료)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

# HTTP 리스너 (HTTPS로 리디렉션)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

# CNAME 레코드 생성 (도메인 관리를 Route 53에서 할 경우 사용)
resource "aws_route53_record" "nlb_record" {
  count   = var.create_route53_record ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = aws_lb.nlb.dns_name
    zone_id                = aws_lb.nlb.zone_id
    evaluate_target_health = true
  }
}