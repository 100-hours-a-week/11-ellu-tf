resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = var.private_rds_subnet_ids

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "rds_primary" {
  identifier           = "rds-primary"
  allocated_storage    = var.db_storage_size
  storage_type         = var.db_storage_type
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = var.db_parameter_group_name
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [var.rds_security_group_id]
  skip_final_snapshot  = true
  multi_az             = false
  availability_zone    = var.availability_zones[0]
  backup_retention_period = var.db_backup_retention_period # 레플리카 백업
  backup_window          = "12:00-13:00"  # 한국 시간 새벽 3~4시

  tags = {
    Name = "looper-rds-primary"
  }
}

resource "aws_db_instance" "rds_replica" {
  replicate_source_db    = aws_db_instance.rds_primary.identifier
  instance_class         = var.db_instance_class
  engine                 = var.db_engine
  publicly_accessible    = false
  skip_final_snapshot    = true
  availability_zone      = var.availability_zones[1]
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = var.db_parameter_group_name
  tags = {
    Name = "looper-rds-replica"
  }
}