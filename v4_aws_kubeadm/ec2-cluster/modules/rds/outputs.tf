output "rds_primary_endpoint" {
  description = "Primary RDS instance endpoint"
  value       = aws_db_instance.rds_primary.endpoint
}

output "rds_replica_endpoint" {
  description = "레플리카 RDS 인스턴스 엔드포인트"
  value       = aws_db_instance.rds_replica.endpoint
}