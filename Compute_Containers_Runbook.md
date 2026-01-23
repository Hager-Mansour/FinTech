# AWS Compute & Containers Runbook

**Category:** 3 – Compute & Containers
**Project:** FinTech Global Platform
**Target Environment:** Production (`us-east-1`)
**Version:** 1.0 (Strict Compliance)
**Last Updated:** 2026-01-23
**Author:** Cloud Architecture Team

---

## 1. ECS Cluster Setup (Foundation)

**Objective:** Create a SOC2-compliant, multi-AZ ECS Cluster using Fargate and Spot instances for cost optimization.

### 1.1 Create ECS Cluster
**CLI Commands:**
```bash
# 1. Create Cluster with Capacity Providers
aws ecs create-cluster \
  --cluster-name fintech-prod-cluster \
  --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=2 capacityProvider=FARGATE,weight=1 \
  --tags key=Environment,value=Production key=Project,value=FinTechGlobal key=CostCenter,value=CC-Corp \
  --settings name=containerInsights,value=enabled

# 2. Validation
aws ecs describe-clusters --clusters fintech-prod-cluster --include SETTINGS STATISTICS TAGS
```
*Expected Output:* Status `ACTIVE`, ContainerInsights `ENABLED`, Capacity Providers listed.

---

### 1.2 ECR Repository Setup (Security First)
**Requirements:** Image scanning, encryption, and lifecycle management.

**CLI Commands:**
```bash
# 1. Create Repository (Encrypted & Scanning Enabled)
aws ecr create-repository \
  --repository-name fintech-api \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=KMS \
  --image-tag-mutability IMMUTABLE \
  --tags Key=Environment,Value=Production Key=Project,Value=FinTechGlobal

# 2. Apply Lifecycle Policy (Clean up old images)
cat > lifecycle-policy.json << 'EOF'
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 production images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["prod"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": { "type": "expire" }
        }
    ]
}
EOF

aws ecr put-lifecycle-policy --repository-name fintech-api --lifecycle-policy-text file://lifecycle-policy.json
```

---

### 1.3 IAM Roles (Least Privilege)

#### A. ECS Task Execution Role
*Role assumed by the **ECS Agent** to pull images and push logs.*

**Trust Policy (`ecs-trust.json`):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Principal": { "Service": "ecs-tasks.amazonaws.com" }, "Action": "sts:AssumeRole" }
  ]
}
```

**Permission Policy (`exec-policy.json`):**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "secretsmanager:GetSecretValue",
                "ssm:GetParameters"
            ],
            "Resource": "*"
        }
    ]
}
```

**CLI Commands:**
```bash
# Create Execution Role
aws iam create-role --role-name FinTech-ECS-ExecRole --assume-role-policy-document file://ecs-trust.json
aws iam put-role-policy --role-name FinTech-ECS-ExecRole --policy-name ExecPermissions --policy-document file://exec-policy.json
```

#### B. ECS Task Role
*Role assumed by the **Application Container** to access AWS Services.*

**Permission Policy (`task-policy.json`):**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:Query",
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:dynamodb:us-east-1:*:table/FinTechTransactions",
                "arn:aws:s3:::fintech-data-lake-prod/*"
            ]
        }
    ]
}
```

**CLI Commands:**
```bash
# Create Task Role
aws iam create-role --role-name FinTech-ECS-TaskRole --assume-role-policy-document file://ecs-trust.json
aws iam put-role-policy --role-name FinTech-ECS-TaskRole --policy-name AppPermissions --policy-document file://task-policy.json
```

---

### 1.4 Task Definition (Multi-Container)

**Components:**
1.  **API Container:** Main application (Port 8080).
2.  **Log Router:** Fluent Bit sidecar for log shipping.
3.  **Secrets:** Injected safely from Secrets Manager.

**CLI Commands:**
```bash
# Create Log Group
aws logs create-log-group --log-group-name /ecs/fintech-api --tags Key=Environment,Value=Production

# Register Task Definition
aws ecs register-task-definition \
  --family fintech-api-task \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 1024 \
  --memory 2048 \
  --execution-role-arn arn:aws:iam::${ACCOUNT_ID}:role/FinTech-ECS-ExecRole \
  --task-role-arn arn:aws:iam::${ACCOUNT_ID}:role/FinTech-ECS-TaskRole \
  --container-definitions '[
    {
      "name": "api-container",
      "image": "'${ACCOUNT_ID}'.dkr.ecr.us-east-1.amazonaws.com/fintech-api:latest",
      "essential": true,
      "portMappings": [{"containerPort": 8080, "protocol": "tcp"}],
      "secrets": [
        {"name": "DB_PASSWORD", "valueFrom": "arn:aws:secretsmanager:us-east-1:'${ACCOUNT_ID}':secret:fintech/db-credentials:password::"}
      ],
      "environment": [
        {"name": "ENV", "value": "production"},
        {"name": "REGION", "value": "us-east-1"}
      ],
      "logConfiguration": {
        "logDriver": "awsfirelens",
        "options": {
            "Name": "cloudwatch",
            "region": "us-east-1",
            "log_group_name": "/ecs/fintech-api",
            "log_stream_prefix": "app"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      }
    },
    {
      "name": "log_router",
      "image": "amazon/aws-for-fluent-bit:latest",
      "essential": true,
      "firelensConfiguration": {"type": "fluentbit"},
      "memoryReservation": 50
    }
  ]'
```

---

### 1.5 ALB Integration

**Objective:** Secure, load-balanced traffic entry.

**CLI Commands:**
```bash
# 1. Create Target Group
TG_ARN=$(aws elbv2 create-target-group \
  --name fintech-prod-tg \
  --protocol HTTP --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path "/health" \
  --health-check-interval-seconds 30 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# Tune Deregistration Delay (Fast convergence)
aws elbv2 modify-target-group-attributes --target-group-arn $TG_ARN --attributes Key=deregistration_delay.timeout_seconds,Value=30 Key=stickiness.enabled,Value=false

# 2. Create Listener (TLS Required)
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS --port 443 \
  --certificates CertificateArn=$CERT_ARN \
  --ssl-policy ELBSecurityPolicy-TLS-1-2-2017-01 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

---

### 1.6 ECS Service Creation

**Configuration:**
-   **Service Name:** `fintech-api-svc`
-   **Launch Type:** FARGATE
-   **Desired Count:** 3 (High Availability)
-   **Deployment Strategy:** Rolling Update (Circuit Breaker Enabled)

**CLI Commands:**
```bash
aws ecs create-service \
  --cluster fintech-prod-cluster \
  --service-name fintech-api-svc \
  --task-definition fintech-api-task \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$APP_SUB_A,$APP_SUB_B],securityGroups=[$ECS_SG],assignPublicIp=DISABLED}" \
  --load-balancers targetGroupArn=$TG_ARN,containerName=api-container,containerPort=8080 \
  --health-check-grace-period-seconds 60 \
  --deployment-configuration "deploymentCircuitBreaker={enable=true,rollback=true}" \
  --tags key=Environment,value=Production
```

---

## 2. Platform Auto Scaling (50 Points)

### 2.1 ECS Auto Scaling
**Strategy:** Target Tracking on CPU (70%) and Memory (75%).

**CLI Commands:**
```bash
# 1. Register Scalable Target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/fintech-prod-cluster/fintech-api-svc \
  --min-capacity 3 \
  --max-capacity 10

# 2. CPU Policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/fintech-prod-cluster/fintech-api-svc \
  --policy-name fintech-cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": { "PredefinedMetricType": "ECSServiceAverageCPUUtilization" },
    "ScaleOutCooldown": 60,
    "ScaleInCooldown": 300
  }'

# 3. Memory Policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/fintech-prod-cluster/fintech-api-svc \
  --policy-name fintech-mem-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 75.0,
    "PredefinedMetricSpecification": { "PredefinedMetricType": "ECSServiceAverageMemoryUtilization" }
  }'
```

### 2.2 Aurora Auto Scaling (Reader Replicas)
**Objective:** Scale read capacity for reporting/analytics.

**CLI Commands:**
```bash
# Register Target
aws application-autoscaling register-scalable-target \
  --service-namespace rds \
  --resource-id cluster:fintech-db-cluster \
  --scalable-dimension rds:cluster:ReadReplicaCount \
  --min-capacity 1 \
  --max-capacity 5

# Policy
aws application-autoscaling put-scaling-policy \
  --service-namespace rds \
  --resource-id cluster:fintech-db-cluster \
  --scalable-dimension rds:cluster:ReadReplicaCount \
  --policy-name aurora-read-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 60.0,
    "PredefinedMetricSpecification": { "PredefinedMetricType": "RDSReaderAverageCPUUtilization" }
  }'
```

### 2.3 DynamoDB Auto Scaling
**Configuration:** Target utilization 70%.

**CLI Commands:**
```bash
# Write Capacity
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/FinTechTransactions \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --min-capacity 5 \
  --max-capacity 100

aws application-autoscaling put-scaling-policy \
  --service-namespace dynamodb \
  --resource-id table/FinTechTransactions \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --policy-name dynamodb-write-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": { "PredefinedMetricType": "DynamoDBWriteCapacityUtilization" }
  }'
```

### 2.4 Custom Business Metrics
**Requirement:** Push business-level metrics for advanced scaling/monitoring.

**CLI Examples:**
```bash
# 1. Transactions Processed
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name TransactionsProcessed --value 150 --unit Count --dimensions Service=PaymentAPI

# 2. Login Success
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name LoginSuccess --value 1 --unit Count --dimensions Service=Auth

# 3. Fraud Flags
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name FraudFlags --value 0 --unit Count

# 4. API Errors
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name APIErrors --value 2 --unit Count

# 5. Payment Latency
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name PaymentLatency --value 120 --unit Milliseconds
```

---

## 3. Security & Compliance Checklist

1.  **Strict Isolation:** ECS Tasks run ONLY in Private Subnets (`$APP_SUB_A`, `$APP_SUB_B`). No Public IPs.
2.  **Secrets Management:** ALL sensitive data (DB passwords, Keys) MUST be in Secrets Manager. No cleartext ENVs.
3.  **Logs Encryption:** CloudWatch Log Groups encrypted with KMS.
4.  **Network Security:** Security Groups allow port 8080 ONLY from ALB SG.
5.  **Immutability:** ECR Image Tag Mutability = `IMMUTABLE`.

---

## 4. Operational Excellence

### 4.1 Post-Deployment Validation
| Check | Command | Expected |
|:--- |:--- |:--- |
| **Service Stable** | `aws ecs describe-services ...` | `status: ACTIVE`, `runningCount: 3` |
| **Tasks Healthy** | Check Target Group Health | All targets `healthy` |
| **Scaling Ready** | `aws application-autoscaling describe-scalable-targets ...` | Targets registered |
| **Logs Flowing** | Check CloudWatch `/ecs/fintech-api` | Startup logs present |

### 4.2 Failure Scenarios & Troubleshooting
1.  **Task CrashLoop:**
    *   *Cause:* Bad code or config.
    *   *Fix:* Check logs (`aws logs get-log-events`). Circuit breaker will auto-rollback.
    *   *Command:* `aws ecs update-service --force-new-deployment` (after fix).
2.  **Scale Out Failure:**
    *   *Cause:* Hit Max Capacity or Subnet IP exhaustion.
    *   *Fix:* Increase `MaxCapacity` or check Subnet CIDR usage.

### 4.3 Rollback Strategy
If a new deployment fails:
1.  ECS Circuit Breaker will attempt auto-rollback.
2.  **Manual Rollback:**
    ```bash
    # Update service to previous Task Definition version
    aws ecs update-service --service fintech-api-svc --task-definition fintech-api-task:<PREVIOUS_REV>
    ```

---
