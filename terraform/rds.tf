# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "fintech-db-subnets"
  subnet_ids = aws_subnet.private_db[*].id

  tags = {
    Name = "fintech-db-subnets"
  }
}

# Aurora Security Group
resource "aws_security_group" "rds" {
  name        = "fintech-db-sg"
  description = "Security group for Aurora database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name = "fintech-db-sg"
  }
}

# Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "fintech-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "15.8"
  database_name           = "fintech"
  master_username         = "fintechadmin"
  master_password         = "password123" # Use secret in production
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.main.arn
  backup_retention_period = 35
  preferred_backup_window = "03:00-04:00"
  skip_final_snapshot     = true
  deletion_protection     = false # Set to true for production

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "fintech-cluster"
  }
}

resource "aws_rds_cluster_instance" "main" {
  count                = 2
  identifier           = "fintech-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = "db.t4g.medium" # Using small instance for labs
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  db_subnet_group_name = aws_db_subnet_group.main.name

  tags = {
    Name = "fintech-instance-${count.index}"
  }
}
