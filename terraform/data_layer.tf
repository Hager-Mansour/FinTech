# DynamoDB Tables
resource "aws_dynamodb_table" "sessions" {
  name           = "fintech-sessions"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "userId"
  range_key      = "sessionId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "sessionId"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }

  tags = {
    Name = "fintech-sessions"
  }
}

resource "aws_dynamodb_table" "transactions" {
  name         = "fintech-transactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "transactionId"

  attribute {
    name = "transactionId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  global_secondary_index {
    name            = "userId-timestamp"
    hash_key        = "userId"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }

  tags = {
    Name = "fintech-transactions"
  }
}

resource "aws_dynamodb_table" "accounts" {
  name         = "fintech-accounts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "accountId"

  attribute {
    name = "accountId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  global_secondary_index {
    name            = "userId-index"
    hash_key        = "userId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }

  tags = {
    Name = "fintech-accounts"
  }
}

# DynamoDB Auto Scaling
resource "aws_appautoscaling_target" "dynamodb_read" {
  max_capacity       = 100
  min_capacity       = 5
  resource_id        = "table/${aws_dynamodb_table.sessions.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_read_policy" {
  name               = "read-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_read.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_read.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_read.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

# S3 Data Lake
resource "aws_s3_bucket" "data_lake" {
  bucket_prefix = "fintech-data-lake-"
}

resource "aws_s3_bucket" "logs" {
  bucket_prefix = "fintech-logs-"
}

resource "aws_s3_bucket_logging" "data_lake" {
  bucket        = aws_s3_bucket.data_lake.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "ArchiveOldData"
    status = "Enabled"

    filter {
      prefix = "archive/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "DeleteOldVersions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "main" {
  name       = "fintech-redis-subnets"
  subnet_ids = aws_subnet.private_db[*].id
}

resource "aws_security_group" "redis" {
  name        = "fintech-redis-sg"
  description = "Security group for Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name = "fintech-redis-sg"
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "fintech-redis-cluster"
  description                = "Redis cluster for caching"
  node_type                  = "cache.t4g.small"
  num_cache_clusters         = 2
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = "D0ntUs3Th1sInPr0ducti0n123!" # Should be a secret
  automatic_failover_enabled = true
  multi_az_enabled           = true

  tags = {
    Name = "fintech-redis-cluster"
  }
}
