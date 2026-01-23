# AWS Data Layer & Secrets Management Runbook

**Category:** 4 – Data Layer & Secrets Management
**Project:** FinTech Global Platform
**Target Environment:** Production (`us-east-1`)
**Version:** 3.0 (Strict SOC2/PCI Compliance - Final)
**Last Updated:** 2026-01-23
**Author:** Cloud Architecture Team

---

## 1. Security Foundation (KMS & Secrets First)

**Objective:** Establish a "Zero Trust" data encryption foundation using Customer Managed Keys (CMKs) and enforced Service Restrictions.

### 1.1 Customer Managed KMS Key (CMK)
**Requirement:** Restrict key usage to specific AWS services via `kms:ViaService`.

**CLI Commands:**
```bash
# 1. Create Strict Key Policy
cat > kms-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::<ACCOUNT_ID>:root"},
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow Services",
      "Effect": "Allow",
      "Principal": {
        "Service": [
            "rds.amazonaws.com",
            "dynamodb.amazonaws.com",
            "s3.amazonaws.com",
            "secretsmanager.amazonaws.com",
            "elasticache.amazonaws.com"
        ]
      },
      "Action": ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": [
            "rds.us-east-1.amazonaws.com",
            "dynamodb.us-east-1.amazonaws.com",
            "s3.us-east-1.amazonaws.com",
            "secretsmanager.us-east-1.amazonaws.com",
            "elasticache.us-east-1.amazonaws.com"
          ]
        }
      }
    }
  ]
}
EOF

# 2. Create Key
KMS_KEY_ID=$(aws kms create-key --description "FinTech Production Data Key" --policy file://kms-policy.json --tags TagKey=Project,TagValue=FinTechGlobal --query 'KeyMetadata.KeyId' --output text)
aws kms create-alias --alias-name alias/fintech-prod-key --target-key-id $KMS_KEY_ID
aws kms enable-key-rotation --key-id $KMS_KEY_ID
```

### 1.2 Secrets Management Setup
**Requirement:** Create base secrets structure BEFORE resource deployment.

**CLI Commands:**
```bash
# 1. DB Credentials (Placeholder structure, content managed by RDS later)
aws secretsmanager create-secret --name fintech/db-credentials --description "Master DB Auth" --kms-key-id $KMS_KEY_ID

# 2. API Keys
aws secretsmanager create-secret --name fintech/api-keys --secret-string '{"stripe":"pk_live_..."}' --kms-key-id $KMS_KEY_ID

# 3. Encryption Key (App Layer)
aws secretsmanager create-secret --name fintech/encryption-key --secret-string $(openssl rand -base64 32) --kms-key-id $KMS_KEY_ID

# 4. Redis Auth
REDIS_TOKEN=$(openssl rand -hex 16)
aws secretsmanager create-secret --name fintech/redis-auth --secret-string $REDIS_TOKEN --kms-key-id $KMS_KEY_ID
```

---

## 2. Aurora PostgreSQL (50 Points)

**Objective:** Banking-grade database with custom tuning, secrets integration, and encryption.

### 2.1 Parameter Group Tuning
**Requirement:** Enable strict logging for auditing.

**CLI Commands:**
```bash
# 1. Create Parameter Group
aws rds create-db-cluster-parameter-group \
  --db-cluster-parameter-group-name fintech-aurora-params \
  --db-parameter-group-family aurora-postgresql13 --description "FinTech Strict Logging"

# 2. Modify Parameters
aws rds modify-db-cluster-parameter-group \
  --db-cluster-parameter-group-name fintech-aurora-params \
  --parameters "ParameterName=log_statement,ParameterValue=ddl,ApplyMethod=immediate" \
               "ParameterName=log_min_duration_statement,ParameterValue=500,ApplyMethod=immediate" \
               "ParameterName=idle_in_transaction_session_timeout,ParameterValue=60000,ApplyMethod=immediate"
```

### 2.2 Aurora Cluster Creation
**CLI Commands:**
```bash
# 1. Private Subnet Group
aws rds create-db-subnet-group --db-subnet-group-name fintech-db-subnet-group \
  --db-subnet-group-description "Private DB Subnets" --subnet-ids $DB_SUB_A $DB_SUB_B

# 2. Create Cluster (Managed Secret + CMK Encryption)
AURORA_ARN=$(aws rds create-db-cluster \
  --db-cluster-identifier fintech-db-cluster \
  --engine aurora-postgresql \
  --master-username fintech_admin \
  --manage-master-user-password \
  --master-user-secret-kms-key-id $KMS_KEY_ID \
  --db-subnet-group-name fintech-db-subnet-group \
  --db-cluster-parameter-group-name fintech-aurora-params \
  --vpc-security-group-ids $SG_DB \
  --backup-retention-period 35 \
  --preferred-backup-window "03:00-04:00" \
  --storage-encrypted \
  --kms-key-id $KMS_KEY_ID \
  --enable-cloudwatch-logs-exports postgresql \
  --deletion-protection \
  --copy-tags-to-snapshot \
  --tags Key=Environment,Value=Production \
  --query 'DBCluster.DBClusterArn' --output text)

# 3. Create Writer (AZ-A)
aws rds create-db-instance \
  --db-instance-identifier fintech-db-writer \
  --db-cluster-identifier fintech-db-cluster \
  --engine aurora-postgresql --db-instance-class db.r6g.large \
  --availability-zone us-east-1a \
  --enable-performance-insights --performance-insights-kms-key-id $KMS_KEY_ID

# 4. Create Reader (AZ-B)
aws rds create-db-instance \
  --db-instance-identifier fintech-db-reader-1 \
  --db-cluster-identifier fintech-db-cluster \
  --engine aurora-postgresql --db-instance-class db.r6g.large \
  --availability-zone us-east-1b \
  --enable-performance-insights --performance-insights-kms-key-id $KMS_KEY_ID
```

### 2.3 Aurora Auto Scaling
**Policy:** Scale Readers (1-5) at 60% CPU.

**CLI Commands:**
```bash
aws application-autoscaling register-scalable-target \
  --service-namespace rds --resource-id cluster:fintech-db-cluster \
  --scalable-dimension rds:cluster:ReadReplicaCount --min-capacity 1 --max-capacity 5

aws application-autoscaling put-scaling-policy \
  --service-namespace rds --resource-id cluster:fintech-db-cluster \
  --scalable-dimension rds:cluster:ReadReplicaCount \
  --policy-name aurora-cpu-scaling --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 60.0,
    "PredefinedMetricSpecification": { "PredefinedMetricType": "RDSReaderAverageCPUUtilization" },
    "ScaleOutCooldown": 300, "ScaleInCooldown": 300
  }'
```

---

## 3. DynamoDB Enterprise (40 Points)

**Objective:** Encrypted NoSQL with Streams and PITR.

### 3.1 Table Creation
**CLI Commands:**
```bash
# 1. Sessions Table
aws dynamodb create-table --table-name FinTechSessions \
  --attribute-definitions AttributeName=UserId,AttributeType=S AttributeName=SessionId,AttributeType=S \
  --key-schema AttributeName=UserId,KeyType=HASH AttributeName=SessionId,KeyType=RANGE \
  --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES \
  --sse-specification Enabled=true,SSEType=KMS,KMSMasterKeyId=$KMS_KEY_ID \
  --tags Key=Environment,Value=Production

# Enable PITR (Point-In-Time Recovery)
aws dynamodb update-continuous-backups --table-name FinTechSessions \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true

# 2. Transactions Table (GSI)
aws dynamodb create-table --table-name FinTechTransactions \
  --attribute-definitions AttributeName=TransactionId,AttributeType=S AttributeName=AccountId,AttributeType=S \
  --key-schema AttributeName=TransactionId,KeyType=HASH \
  --global-secondary-indexes '[{
      "IndexName": "AccountIndex",
      "KeySchema":[{"AttributeName":"AccountId","KeyType":"HASH"}],
      "Projection":{"ProjectionType":"ALL"},
      "ProvisionedThroughput":{"ReadCapacityUnits":10,"WriteCapacityUnits":10}
  }]' \
  --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 \
  --sse-specification Enabled=true,SSEType=KMS,KMSMasterKeyId=$KMS_KEY_ID

aws dynamodb update-continuous-backups --table-name FinTechTransactions \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true

# 3. Accounts Table (GSI)
aws dynamodb create-table --table-name FinTechAccounts \
  --attribute-definitions AttributeName=AccountId,AttributeType=S AttributeName=Email,AttributeType=S \
  --key-schema AttributeName=AccountId,KeyType=HASH \
  --global-secondary-indexes '[{
      "IndexName": "EmailIndex",
      "KeySchema":[{"AttributeName":"Email","KeyType":"HASH"}],
      "Projection":{"ProjectionType":"ALL"},
      "ProvisionedThroughput":{"ReadCapacityUnits":10,"WriteCapacityUnits":10}
  }]' \
  --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 \
  --sse-specification Enabled=true,SSEType=KMS,KMSMasterKeyId=$KMS_KEY_ID

aws dynamodb update-continuous-backups --table-name FinTechAccounts \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

### 3.2 DynamoDB Auto Scaling
**Target:** 70% Utils.

**CLI Commands (Apply to all tables):**
```bash
aws application-autoscaling register-scalable-target --service-namespace dynamodb \
  --resource-id table/FinTechTransactions --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --min-capacity 10 --max-capacity 1000

aws application-autoscaling put-scaling-policy --service-namespace dynamodb \
  --resource-id table/FinTechTransactions --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --policy-name tx-write-scaling --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0, "PredefinedMetricSpecification": { "PredefinedMetricType": "DynamoDBWriteCapacityUtilization" }
  }'
```

---

## 4. S3 Data Lake (30 Points)

**Objective:** Audit-ready storage with Logging and Replication.

### 4.1 Buckets & Logging
**CLI Commands:**
```bash
SRC_BUCKET="fintech-prod-data-$(date +%s)"
DEST_BUCKET="fintech-prod-data-replica-$(date +%s)"
LOG_BUCKET="fintech-prod-logs-$(date +%s)"

# 1. Create Logging Bucket (Security)
aws s3api create-bucket --bucket $LOG_BUCKET --region us-east-1
aws s3api put-bucket-acl --bucket $LOG_BUCKET --acl log-delivery-write
aws s3api put-bucket-encryption --bucket $LOG_BUCKET --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# 2. Create Source & Replica with Logging
aws s3api create-bucket --bucket $SRC_BUCKET --region us-east-1
aws s3api create-bucket --bucket $DEST_BUCKET --region us-east-1

aws s3api put-bucket-logging --bucket $SRC_BUCKET --bucket-logging-status '{"LoggingEnabled":{"TargetBucket":"'$LOG_BUCKET'","TargetPrefix":"source-logs/"}}'
aws s3api put-bucket-logging --bucket $DEST_BUCKET --bucket-logging-status '{"LoggingEnabled":{"TargetBucket":"'$LOG_BUCKET'","TargetPrefix":"replica-logs/"}}'

# 3. Encryption (bucket key)
ENC_CONFIG='{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms", "KMSMasterKeyID": "'$KMS_KEY_ID'"}, "BucketKeyEnabled": true}]}'
aws s3api put-bucket-encryption --bucket $SRC_BUCKET --server-side-encryption-configuration "$ENC_CONFIG"

# 4. Block Public Access
BPA="BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
aws s3api put-public-access-block --bucket $SRC_BUCKET --public-access-block-configuration "$BPA"
```

### 4.2 Replication & Lifecycle
**CLI Commands:**
```bash
# Enable Versioning
aws s3api put-bucket-versioning --bucket $SRC_BUCKET --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning --bucket $DEST_BUCKET --versioning-configuration Status=Enabled

# Apply Replication (Same Region)
aws s3api put-bucket-replication --bucket $SRC_BUCKET --replication-configuration file://replication.json

# Apply Lifecycle (Intelligent Tiering -> Glacier)
aws s3api put-bucket-lifecycle-configuration --bucket $SRC_BUCKET --lifecycle-configuration '{
  "Rules": [
    { "ID": "Archive", "Status": "Enabled", "Prefix": "archive/", "Transitions": [{"Days": 90, "StorageClass": "GLACIER"}], "NoncurrentVersionExpiration": {"NoncurrentDays": 90} },
    { "ID": "Tiering", "Status": "Enabled", "Prefix": "raw/", "Transitions": [{"Days": 0, "StorageClass": "INTELLIGENT_TIERING"}] }
  ]
}'
```

---

## 5. ElastiCache Redis (30 Points)

**Objective:** Encrypted Cache.

### 5.1 Cluster Setup
**CLI Commands:**
```bash
aws elasticache create-cache-subnet-group --cache-subnet-group-name fintech-redis-subnet --subnet-ids $DB_SUB_A $DB_SUB_B

aws elasticache create-replication-group \
  --replication-group-id fintech-redis \
  --replication-group-description "FinTech Prod Redis" \
  --engine redis --cache-node-type cache.t4g.medium \
  --num-node-groups 1 --replicas-per-node-group 1 \
  --cache-subnet-group-name fintech-redis-subnet \
  --security-group-ids $SG_REDIS \
  --multi-az-enabled --automatic-failover-enabled \
  --at-rest-encryption-enabled --transit-encryption-enabled \
  --auth-token $REDIS_TOKEN --kms-key-id $KMS_KEY_ID \
  --snapshot-retention-limit 7 \
  --snapshot-window "04:00-05:00"
```

---

## 6. Secrets Manager & IAM (30 Points)

**Objective:** Least Privilege Access.

### 6.1 Rotation & Policy
**CLI Commands:**
```bash
# Enable Rotation for DB Secret
aws secretsmanager rotate-secret --secret-id <AURORA_SECRET_ARN> \
  --rotation-lambda-arn <LAMBDA_ARN> --rotation-rules AutomaticallyAfterDays=30
```

### 6.2 IAM Least Privilege Policy
**Policy Content:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["secretsmanager:GetSecretValue"],
            "Resource": ["arn:aws:secretsmanager:us-east-1:*:secret:fintech/*"]
        },
        {
            "Effect": "Allow",
            "Action": ["kms:Decrypt"],
            "Resource": ["arn:aws:kms:us-east-1:*:key/<KMS_KEY_ID>"]
        }
    ]
}
```
*Attach ONLY to `FinTech-ECS-TaskRole`.*

---

## 7. Operational Excellence

### 7.1 Validation Commands
| Check | Command | Expected |
|:--- |:--- |:--- |
| **KMS ViaService** | Inspect Key Policy | `Condition: kms:ViaService` |
| **S3 Logging** | `aws s3api get-bucket-logging` | TargetBucket populated |
| **Param Group** | `aws rds describe-db-parameters` | `log_statement = ddl` |
| **Aurora Encrypt** | `aws rds describe-db-clusters` | `KmsKeyId` present |
| **PITR Status** | `aws dynamodb describe-continuous-backups` | `PointInTimeRecoveryStatus: ENABLED` |

### 7.2 Post-Deployment Checklist
- [ ] KMS Key Policy restricts access to AWS Services.
- [ ] All Secrets created (API, Redis, DB, Encryption).
- [ ] S3 Logging Bucket exists and is receiving logs.
- [ ] Aurora Parameter Group applied and active (reboot may be required).
- [ ] DynamoDB PITR enabled on all 3 tables.
- [ ] Redis Auth Token verified.
