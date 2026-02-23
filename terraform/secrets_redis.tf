# Redis Auth Secret
resource "aws_secretsmanager_secret" "redis_auth" {
  name        = "fintech/redis-auth-v2"
  description = "ElastiCache Redis authentication token"
  kms_key_id  = aws_kms_key.main.arn

  tags = {
    Name = "fintech-redis-auth"
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = "D0ntUs3Th1sInPr0ducti0n123!"
}
