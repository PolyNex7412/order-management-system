# RDS サブネットグループ（プライベートサブネット × 2AZ が必要）
resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.common_tags, { Name = "${local.name}-db-subnet-group" })
}

# RDS PostgreSQL（Single-AZ / dev 環境向けの最小構成）
resource "aws_db_instance" "main" {
  identifier = "${local.name}-postgres"

  engine         = "postgres"
  engine_version = "15.5"
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # ストレージ
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # バックアップ（dev は短め）
  backup_retention_period = 3
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # 削除保護（dev では無効にして terraform destroy を通しやすくする）
  deletion_protection       = false
  skip_final_snapshot       = true
  delete_automated_backups  = true

  # 本番では true にして Multi-AZ にすること
  multi_az = false

  tags = merge(local.common_tags, { Name = "${local.name}-rds" })
}
