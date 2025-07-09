output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.nlb.dns_name
}

output "nlb_zone_id" {
  description = "Zone ID of the Network Load Balancer"
  value       = aws_lb.nlb.zone_id
}

output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.nlb.arn
}

output "target_group_http_arn" {
  description = "ARN of the HTTP target group"
  value       = aws_lb_target_group.http.arn
}

output "target_group_https_arn" {
  description = "ARN of the HTTPS target group"
  value       = aws_lb_target_group.https.arn
}