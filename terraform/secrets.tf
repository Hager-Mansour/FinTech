# KMS Key for Encryption
resource "aws_kms_key" "main" {
  description             = "Main encryption key for FinTech platform"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "fintech-main-key"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/fintech-main-key"
  target_key_id = aws_kms_key.main.key_id
}

# DB Credentials Secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "fintech/db-credentials"
  description = "Aurora database credentials"
  kms_key_id  = aws_kms_key.main.arn

  tags = {
    Name = "fintech-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "fintechadmin"
    password = "password123" # In production, use random generated password
    engine   = "postgres"
    port     = 5432
    dbname   = "fintech"
  })
}

# API Keys Secret
resource "aws_secretsmanager_secret" "api_keys" {
  name        = "fintech/api-keys"
  description = "API keys for external services"
  kms_key_id  = aws_kms_key.main.arn

  tags = {
    Name = "fintech-api-keys"
  }
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    stripe_api_key   = "sk_test_placeholder"
    sendgrid_api_key = "SG.placeholder"
  })
}
