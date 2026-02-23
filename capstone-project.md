# AWS Architecting Capstone Project

## FinTech Global Platform - Comprehensive Enterprise Solution

---

## 🎯 Project Overview

Design, implement, and deploy a complete **production-grade financial technology platform** that demonstrates mastery of all AWS services and architectural patterns covered throughout the course.

**Difficulty Level:** ⭐⭐⭐⭐ (Advanced)
**Estimated Duration:** 20-30 hours
**Total Points:** 625 points
**Passing Score:** 375 points (60%)

---

## 📋 Scenario: FinTech Global

**FinTech Global** is a rapidly growing financial services company launching a new digital banking platform with the following requirements:

### Business Requirements

| Requirement | Target | Priority |
|-------------|--------|----------|
| Transaction Processing | 1,000 TPS peak | Critical |
| User Base | 500,000 users | High |
| Availability | 99.9% (8.7 hours downtime/year) | Critical |
| Response Time | < 200ms for API calls | High |
| Data Retention | 7 years for compliance | Critical |
| Geographic Coverage | Single region (us-east-1) | High |
| Compliance | SOC 2 | Critical |

### Technical Requirements

- **Cost Optimization:** 40% reduction from baseline

---

## 🏗️ Target Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    FINTECH GLOBAL PLATFORM ARCHITECTURE                                     │
│                                            Single Region (us-east-1)                                        │
│                                                                                                             │
│                                         ┌──────────────────────┐                                            │
│                                         │      CloudFront       │                                           │
│                                         └──────────┬───────────┘                                            │
│                                                    │                                                        │
│                                         ┌──────────▼───────────┐                                            │
│                                         │   ALB (Multi-AZ)     │                                            │
│                                         └──────────┬───────────┘                                            │
│                                                    │                                                        │
│                                         ┌──────────▼───────────┐                                            │
│                                         │   ECS Cluster        │                                            │
│                                         │   (Fargate + EC2)    │                                            │
│                                         │   ┌────┐ ┌────┐      │                                            │
│                                         │   │Task│ │Task│...   │                                            │
│                                         │   └────┘ └────┘      │                                            │
│                                         └──────────┬───────────┘                                            │
│                                                    │                                                        │
│                          ┌─────────────────────────┼─────────────────────────┐                              │
│                          │                         │                         │                              │
│         ┌────────────────▼────────┐  ┌─────────────▼───────┐  ┌─────────────▼───────┐                       │
│         │  Aurora PostgreSQL      │  │  DynamoDB Table     │  │  ElastiCache Redis  │                       │
│         │  (Multi-AZ Cluster)     │  │  (Sessions/Cache)   │  │  (Multi-AZ Cluster) │                       │
│         │  ┌──────────┐ ┌──────┐  │  │                     │  │  ┌──────┐ ┌──────┐  │                       │
│         │  │ Writer   │ │Reader│  │  │                     │  │  │ Node │ │ Node │  │                       │
│         │  └──────────┘ └──────┘  │  │                     │  │  └──────┘ └──────┘  │                       │
│         └─────────────────────────┘  └─────────────────────┘  └─────────────────────┘                       │
│                                                    │                                                        │
│                                         ┌──────────▼───────────┐                                            │
│                                         │  S3 (Data Lake)      │                                            │
│                                         │ (Encrypted, Versioned)│                                           │
│                                         └──────────────────────┘                                            │
│                                                                                                             │
│                                                                                                             │
│    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│    │                                    OBSERVABILITY LAYER                                              │  │
│    │                                                                                                     │  │
│    │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                                │  │
│    │  │ CloudWatch   │ │ X-Ray        │ │ CloudWatch   │ │ CloudWatch   │                                │  │
│    │  │ Metrics      │ │ (Tracing)    │ │ Logs         │ │ Dashboards   │                                │  │
│    │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘                                │  │
│    └─────────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Scoring Breakdown

### Total Points: 625

| Category | Points | Weight |
|----------|--------|--------|
| **1. Foundation & Organization** | 75 | 12.0% |
| **2. Networking** | 40 | 6.4% |
| **3. Compute & Containers** | 110 | 17.6% |
| **4. Data Layer** | 180 | 28.8% |
| **5. Observability** | 70 | 11.2% |
| **6. Cost Optimization** | 75 | 12.0% |
| **7. High Availability & DR** | 75 | 12.0% |
| **8. Documentation & Presentation** | 100 | 16.0% (Bonus) |

---

## 📝 Detailed Tasks & Scoring Rubric

---

## Category 1: Foundation & Organization (75 Points)

### Task 1.1: AWS Organizations Setup (30 Points)

**Objective:** Create a multi-account structure following AWS best practices.

**Requirements:**

```
Root Account (Management)
├── Security OU
│   ├── Security-Audit Account
│   └── Security-Logging Account
├── Infrastructure OU
│   ├── Shared-Services Account
│   └── Network-Hub Account
├── Workloads OU
│   ├── Production OU
│   │   ├── Prod-US Account
│   │   └── Prod-EU Account
│   ├── Staging OU
│   │   └── Staging Account
│   └── Development OU
│       └── Dev Account
└── Sandbox OU
    └── Sandbox Account
```

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| OU Structure | 10 | All OUs created with proper hierarchy |
| Account Creation | 5 | At least 5 accounts with proper naming |
| SCPs Implementation | 10 | At least 3 SCPs (Deny root, Region restriction, etc.) |
| Consolidated Billing | 5 | Properly configured with budget alerts |

**CLI Commands to Implement:**

```bash
# Create Organization
aws organizations create-organization --feature-set ALL

# Create OUs
aws organizations create-organizational-unit \
  --parent-id r-xxxx \
  --name "Security"

aws organizations create-organizational-unit \
  --parent-id r-xxxx \
  --name "Workloads"

# Create SCP - Deny Root User
cat > deny-root-scp.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyRootUser",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    }
  ]
}
EOF

aws organizations create-policy \
  --name "DenyRootUserAccess" \
  --description "Deny all actions for root user" \
  --type SERVICE_CONTROL_POLICY \
  --content file://deny-root-scp.json

# Create SCP - Region Restriction
cat > region-restriction-scp.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNonApprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "support:*",
        "sts:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1"]
        }
      }
    }
  ]
}
EOF
```

---

### Task 1.2: Tagging Strategy (20 Points)

**Objective:** Implement comprehensive tagging for cost allocation and resource management.

**Required Tags:**

| Tag Key | Example Values | Purpose |
|---------|---------------|---------|
| `Environment` | Production, Staging, Development | Environment identification |
| `Project` | FinTechGlobal | Project association |
| `CostCenter` | CC-12345 | Cost allocation |
| `Owner` | team-platform@company.com | Resource ownership |
| `DataClassification` | Confidential, Internal, Public | Security classification |
| `Compliance` | SOC2, GDPR | Compliance requirements |
| `AutoShutdown` | true/false | Cost optimization |
| `BackupPolicy` | Daily, Weekly, Monthly | Backup requirements |

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Tag Policy Creation | 5 | AWS Organizations tag policy |
| Mandatory Tags Enforcement | 5 | At least 5 mandatory tags |
| Tag Compliance Reporting | 5 | Config rule for tag compliance |
| Cost Allocation Tags | 5 | Tags activated in Cost Explorer |

**Implementation:**

```bash
# Create Tag Policy
cat > tag-policy.json << 'EOF'
{
  "tags": {
    "Environment": {
      "tag_key": {"@@assign": "Environment"},
      "tag_value": {
        "@@assign": ["Production", "Staging", "Development", "Sandbox"]
      },
      "enforced_for": {
        "@@assign": [
          "ec2:instance",
          "ec2:volume",
          "rds:db",
          "s3:bucket",
          "dynamodb:table"
        ]
      }
    },
    "Project": {
      "tag_key": {"@@assign": "Project"}
    },
    "CostCenter": {
      "tag_key": {"@@assign": "CostCenter"},
      "tag_value": {"@@assign": ["CC-*"]}
    },
    "Owner": {
      "tag_key": {"@@assign": "Owner"}
    },
    "DataClassification": {
      "tag_key": {"@@assign": "DataClassification"},
      "tag_value": {"@@assign": ["Confidential", "Internal", "Public"]}
    }
  }
}
EOF

aws organizations create-policy \
  --name "FinTechTagPolicy" \
  --type TAG_POLICY \
  --content file://tag-policy.json

# Create Config Rule for Tag Compliance
aws configservice put-config-rule \
  --config-rule '{
    "ConfigRuleName": "required-tags",
    "Source": {
      "Owner": "AWS",
      "SourceIdentifier": "REQUIRED_TAGS"
    },
    "InputParameters": "{\"tag1Key\":\"Environment\",\"tag2Key\":\"Project\",\"tag3Key\":\"CostCenter\",\"tag4Key\":\"Owner\"}"
  }'
```

---

### Task 1.3: Well-Architected Workload (25 Points)

**Objective:** Create and document a Well-Architected review.

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Workload Creation | 5 | Workload created in WA Tool |
| All Pillars Reviewed | 10 | 6 pillars with answers |
| Improvement Plan | 5 | At least 5 HRIs addressed |
| Milestone Created | 5 | Baseline milestone recorded |

---

## Category 2: Networking (40 Points)

### Task 2.1: VPC Architecture (40 Points)

**Objective:** Design and implement a secure, multi-AZ network topology in a single region.

**Architecture Requirements:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SINGLE REGION VPC ARCHITECTURE                      │
│                              us-east-1                                      │
│                                                                             │
│                    ┌─────────────────────────────────┐                      │
│                    │    Production VPC               │                      │
│                    │      10.0.0.0/16                │                      │
│                    └───────────────┬─────────────────┘                      │
│                                    │                                        │
│                    ┌───────────────▼─────────────────┐                      │
│                    │  Multi-AZ Subnet Design         │                      │
│                    │                                 │                      │
│         ┌──────────┼──────────┐  ┌──────────┼──────────┐                    │
│         │          │          │  │          │          │                    │
│    Public-AZ-A  Private-AZ-A│  │ Public-AZ-B  Private-AZ-B                  │
│   10.0.1.0/24  10.0.11.0/24 │  │ 10.0.2.0/24  10.0.12.0/24                  │
│         │          │          │  │          │          │                    │
│    NAT GW       ECS Tasks    │  │   NAT GW    ECS Tasks                     │
│    ALB          Database     │  │    ALB      Database                      │
│         │          │          │  │          │          │                    │
│         └──────────┼──────────┘  └──────────┼──────────┘                    │
│                    │                        │                               │
│                    └────────────┬───────────┘                               │
│                                 │                                           │
│                    ┌────────────▼───────────┐                               │
│                    │  Database Subnets      │                               │
│                    │  10.0.21.0/24 (AZ-A)   │                               │
│                    │  10.0.22.0/24 (AZ-B)   │                               │
│                    └────────────────────────┘                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

**VPC CIDR Allocation:**

| Component | CIDR | Purpose |
|----------|------|---------|
| Production VPC | 10.0.0.0/16 | All production workloads |
| Public Subnets | 10.0.1.0/24, 10.0.2.0/24 | NAT GW, ALB |
| Private App Subnets | 10.0.11.0/24, 10.0.12.0/24 | ECS Tasks |
| Private DB Subnets | 10.0.21.0/24, 10.0.22.0/24 | Aurora, ElastiCache |

**Subnet Design (per VPC):**

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| VPC Creation | 10 | Proper CIDR, DNS enabled |
| Subnet Design | 10 | Multi-AZ, proper sizing |
| Route Tables | 5 | Proper routing within VPC |
| VPC Endpoints | 10 | S3, DynamoDB, SSM, ECR, Secrets Manager |
| NAT Gateway | 5 | Multi-AZ NAT GW setup |

**Implementation:**

```bash
# Create Production VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=fintech-prod-vpc},{Key=Environment,Value=Production}]' \
  --query 'Vpc.VpcId' --output text)

# Enable DNS
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}'
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support '{"Value":true}'

# Get Availability Zones
AZ_A=$(aws ec2 describe-availability-zones --region us-east-1 --query 'AvailabilityZones[0].ZoneName' --output text)
AZ_B=$(aws ec2 describe-availability-zones --region us-east-1 --query 'AvailabilityZones[1].ZoneName' --output text)

# Create Public Subnets
PUBLIC_SUBNET_A=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone $AZ_A \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fintech-public-az-a}]' \
  --query 'Subnet.SubnetId' --output text)

PUBLIC_SUBNET_B=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone $AZ_B \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fintech-public-az-b}]' \
  --query 'Subnet.SubnetId' --output text)

# Create Private App Subnets
PRIVATE_SUBNET_A=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.11.0/24 \
  --availability-zone $AZ_A \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fintech-private-app-az-a}]' \
  --query 'Subnet.SubnetId' --output text)

PRIVATE_SUBNET_B=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.12.0/24 \
  --availability-zone $AZ_B \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fintech-private-app-az-b}]' \
  --query 'Subnet.SubnetId' --output text)

# Create Database Subnets
DB_SUBNET_A=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.21.0/24 \
  --availability-zone $AZ_A \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fintech-db-az-a}]' \
  --query 'Subnet.SubnetId' --output text)

DB_SUBNET_B=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.22.0/24 \
  --availability-zone $AZ_B \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fintech-db-az-b}]' \
  --query 'Subnet.SubnetId' --output text)

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=fintech-igw}]' \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

# Create Route Table for Public Subnets
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=fintech-public-rt}]' \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_A --route-table-id $PUBLIC_RT_ID
aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_B --route-table-id $PUBLIC_RT_ID

# Create Route Table for Private Subnets
PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=fintech-private-rt}]' \
  --query 'RouteTable.RouteTableId' --output text)

# Create NAT Gateway
EIP_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_A \
  --allocation-id $EIP_ID \
  --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=fintech-nat-gw}]' \
  --query 'NatGateway.NatGatewayId' --output text)

# Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

# Add route to NAT Gateway
aws ec2 create-route --route-table-id $PRIVATE_RT_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_A --route-table-id $PRIVATE_RT_ID
aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_B --route-table-id $PRIVATE_RT_ID

# Create VPC Endpoints
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.s3 \
  --vpc-endpoint-type Gateway \
  --route-table-ids $PRIVATE_RT_ID

# Create Security Group for VPC Endpoints
VPC_ENDPOINT_SG=$(aws ec2 create-security-group \
  --group-name fintech-vpc-endpoint-sg \
  --description "Security group for VPC endpoints" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.ecr.api \
  --vpc-endpoint-type Interface \
  --subnet-ids $PRIVATE_SUBNET_A $PRIVATE_SUBNET_B \
  --security-group-ids $VPC_ENDPOINT_SG \
  --private-dns-enabled

aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.ecr.dkr \
  --vpc-endpoint-type Interface \
  --subnet-ids $PRIVATE_SUBNET_A $PRIVATE_SUBNET_B \
  --security-group-ids $VPC_ENDPOINT_SG \
  --private-dns-enabled

aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.secretsmanager \
  --vpc-endpoint-type Interface \
  --subnet-ids $PRIVATE_SUBNET_A $PRIVATE_SUBNET_B \
  --security-group-ids $VPC_ENDPOINT_SG \
  --private-dns-enabled
```

---

## Category 3: Compute & Containers (110 Points)

### Task 3.1: ECS Cluster Setup (60 Points)

**Objective:** Deploy production-ready containerized application using ECS.

**Cluster Requirements:**

| Component | Specification |
|-----------|--------------|
| Cluster Type | ECS (Fargate + EC2) |
| Launch Type | Fargate (default) + EC2 (optional) |
| Task Definitions | Multi-container, Secrets integration |
| Service Type | Application Load Balancer integration |
| Auto Scaling | Target tracking, CPU/Memory based |
| Secrets | Secrets Manager integration |

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Cluster Creation | 15 | Multi-AZ, proper VPC |
| Task Definitions | 15 | Multi-container, secrets |
| Service Setup | 10 | ALB integration, health checks |
| Auto Scaling | 10 | Target tracking policies |
| IAM Roles | 10 | Task execution and task roles |

**Implementation:**

```bash
# Get Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create ECR Repository
aws ecr create-repository \
  --repository-name fintech-api \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  --tags key=Environment,value=Production key=Project,value=FinTech

ECR_REPO=$(aws ecr describe-repositories --repository-names fintech-api --query 'repositories[0].repositoryUri' --output text)

# Create CloudWatch Log Group
aws logs create-log-group --log-group-name /ecs/fintech-api

# Create ECS Cluster
aws ecs create-cluster \
  --cluster-name fintech-cluster \
  --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy \
    capacityProvider=FARGATE_SPOT,weight=2 \
    capacityProvider=FARGATE,weight=1 \
  --tags key=Environment,value=Production key=Project,value=FinTech

# Create Task Execution Role with Secrets Manager permissions
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create Task Role
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Create Security Group for ECS Tasks
ECS_SG=$(aws ec2 create-security-group \
  --group-name fintech-ecs-sg \
  --description "Security group for ECS tasks" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Create Application Load Balancer
ALB_SG=$(aws ec2 create-security-group \
  --group-name fintech-alb-sg \
  --description "Security group for ALB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Allow HTTP/HTTPS from internet to ALB
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Allow ALB to communicate with ECS tasks
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG \
  --protocol tcp \
  --port 8080 \
  --source-group $ALB_SG

ALB_ARN=$(aws elbv2 create-load-balancer \
  --name fintech-alb \
  --subnets $PUBLIC_SUBNET_A $PUBLIC_SUBNET_B \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --tags Key=Environment,Value=Production Key=Project,Value=FinTech \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Create Target Group
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
  --name fintech-api-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# Create Listener
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN

# Register Task Definition with Secrets Manager integration
aws ecs register-task-definition \
  --family fintech-api \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 512 \
  --memory 1024 \
  --execution-role-arn arn:aws:iam::$ACCOUNT_ID:role/ecsTaskExecutionRole \
  --task-role-arn arn:aws:iam::$ACCOUNT_ID:role/ecsTaskRole \
  --container-definitions "[
    {
      \"name\": \"api-container\",
      \"image\": \"$ECR_REPO:latest\",
      \"portMappings\": [{\"containerPort\": 8080, \"protocol\": \"tcp\"}],
      \"secrets\": [
        {\"name\": \"DB_PASSWORD\", \"valueFrom\": \"arn:aws:secretsmanager:us-east-1:$ACCOUNT_ID:secret:fintech/db-credentials:password::\"},
        {\"name\": \"API_KEY\", \"valueFrom\": \"arn:aws:secretsmanager:us-east-1:$ACCOUNT_ID:secret:fintech/api-keys\"}
      ],
      \"environment\": [
        {\"name\": \"ENVIRONMENT\", \"value\": \"production\"},
        {\"name\": \"REGION\", \"value\": \"us-east-1\"}
      ],
      \"logConfiguration\": {
        \"logDriver\": \"awslogs\",
        \"options\": {
          \"awslogs-group\": \"/ecs/fintech-api\",
          \"awslogs-region\": \"us-east-1\",
          \"awslogs-stream-prefix\": \"ecs\"
        }
      }
    }
  ]"

# Create ECS Service with Auto Scaling
aws ecs create-service \
  --cluster fintech-cluster \
  --service-name fintech-api-service \
  --task-definition fintech-api \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNET_A,$PRIVATE_SUBNET_B],securityGroups=[$ECS_SG],assignPublicIp=DISABLED}" \
  --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=api-container,containerPort=8080 \
  --health-check-grace-period-seconds 60

# Register Auto Scaling Target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/fintech-cluster/fintech-api-service \
  --min-capacity 3 \
  --max-capacity 10

# Create Auto Scaling Policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/fintech-cluster/fintech-api-service \
  --policy-name cpu-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    },
    "ScaleInCooldown": 300,
    "ScaleOutCooldown": 60
  }'
```

---

### Task 3.2: Auto Scaling Configuration (50 Points)

**Objective:** Implement comprehensive auto scaling across all compute resources.

**Scaling Policies Required:**

| Resource | Policy Type | Target |
|----------|-------------|--------|
| ECS Service | Target Tracking | 70% CPU |
| Aurora | Auto Scaling | 70% CPU, 1-5 replicas |
| DynamoDB | Auto Scaling | 70% utilization |
| ElastiCache | Manual/Instance | Multi-AZ setup |

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| ECS Auto Scaling | 20 | Target tracking policies |
| Database Scaling | 20 | Aurora + DynamoDB |
| Custom Metrics | 10 | CloudWatch custom metrics |

---

## Category 4: Data Layer & Secrets Management (180 Points)

### Task 4.1: Aurora PostgreSQL Cluster (50 Points)

**Objective:** Deploy highly available relational database in multi-AZ configuration.

**Architecture:**

```
┌────────────────────────────────────────────────────────────────┐
│                    Aurora PostgreSQL Cluster                   │
│                          us-east-1                             │
│                                                                │
│   ┌─────────────────────────────────────────────────┐          │
│   │            Aurora Cluster (Multi-AZ)            │          │
│   │                                                 │          │
│   │  ┌───────────┐              ┌───────────┐       │          │
│   │  │  Writer   │              │  Reader   │       │          │
│   │  │ Instance  │              │ Instance  │       │          │
│   │  │ (AZ-A)    │              │ (AZ-B)    │       │          │
│   │  └─────┬─────┘              └─────┬─────┘       │          │
│   │        │                          │             │          │
│   │        └──────────┬───────────────┘             │          │
│   │                   │                             │          │
│   │            ┌──────▼──────┐                      │          │
│   │            │  Shared     │                      │          │
│   │            │  Storage    │                      │          │
│   │            │  (6 copies) │                      │          │
│   │            └─────────────┘                      │          │
│   └─────────────────────────────────────────────────┘          │
└────────────────────────────────────────────────────────────────┘
```

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Cluster Creation | 15 | Multi-AZ deployment |
| Instance Config | 10 | Proper sizing, encrypted |
| Parameter Groups | 5 | Optimized parameters |
| Encryption | 10 | KMS encryption, Secrets Manager |
| Backup & Recovery | 10 | PITR, snapshots, retention |

**Implementation:**

```bash
# Create KMS Key for RDS encryption
KMS_KEY_ID=$(aws kms create-key \
  --description "FinTech RDS encryption key" \
  --tags TagKey=Project,TagValue=FinTech TagKey=Environment,TagValue=Production \
  --query 'KeyMetadata.KeyId' --output text)

# Create DB Subnet Group
aws rds create-db-subnet-group \
  --db-subnet-group-name fintech-db-subnets \
  --db-subnet-group-description "Subnets for FinTech Aurora cluster" \
  --subnet-ids $DB_SUBNET_A $DB_SUBNET_B

# Create Security Group for Aurora
DB_SG=$(aws ec2 create-security-group \
  --group-name fintech-db-sg \
  --description "Security group for Aurora database" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Allow ECS tasks to access database
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG \
  --protocol tcp \
  --port 5432 \
  --source-group $ECS_SG

# Generate secure password
DB_PASSWORD=$(openssl rand -base64 32)

# Create Secrets Manager secret for database credentials
aws secretsmanager create-secret \
  --name fintech/db-credentials \
  --description "FinTech Aurora database credentials" \
  --secret-string "{\"username\":\"fintechadmin\",\"password\":\"$DB_PASSWORD\",\"engine\":\"postgres\",\"port\":5432,\"dbname\":\"fintech\"}" \
  --kms-key-id $KMS_KEY_ID

# Create Aurora Cluster
aws rds create-db-cluster \
  --db-cluster-identifier fintech-cluster \
  --engine aurora-postgresql \
  --engine-version 15.4 \
  --master-username fintechadmin \
  --master-user-password $DB_PASSWORD \
  --db-subnet-group-name fintech-db-subnets \
  --vpc-security-group-ids $DB_SG \
  --storage-encrypted \
  --kms-key-id $KMS_KEY_ID \
  --backup-retention-period 35 \
  --preferred-backup-window "03:00-04:00" \
  --enable-cloudwatch-logs-exports postgresql \
  --deletion-protection \
  --enable-http-endpoint \
  --database-name fintech

# Create IAM Role for Enhanced Monitoring
MONITORING_ROLE_ARN=$(aws iam create-role \
  --role-name rds-monitoring-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "monitoring.rds.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' \
  --query 'Role.Arn' --output text)

aws iam attach-role-policy \
  --role-name rds-monitoring-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole

# Create Writer Instance
aws rds create-db-instance \
  --db-instance-identifier fintech-writer \
  --db-instance-class db.r6g.large \
  --db-cluster-identifier fintech-cluster \
  --engine aurora-postgresql \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --monitoring-interval 60 \
  --monitoring-role-arn $MONITORING_ROLE_ARN \
  --publicly-accessible false

# Create Reader Instance (Multi-AZ)
aws rds create-db-instance \
  --db-instance-identifier fintech-reader \
  --db-instance-class db.r6g.large \
  --db-cluster-identifier fintech-cluster \
  --engine aurora-postgresql \
  --enable-performance-insights \
  --publicly-accessible false

# Wait for cluster to be available
aws rds wait db-cluster-available --db-cluster-identifier fintech-cluster

# Enable Aurora Auto Scaling
aws application-autoscaling register-scalable-target \
  --service-namespace rds \
  --resource-id cluster:fintech-cluster \
  --scalable-dimension rds:cluster:ReadReplicaCount \
  --min-capacity 1 \
  --max-capacity 5

aws application-autoscaling put-scaling-policy \
  --service-namespace rds \
  --resource-id cluster:fintech-cluster \
  --scalable-dimension rds:cluster:ReadReplicaCount \
  --policy-name aurora-replica-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "RDSReaderAverageCPUUtilization"
    },
    "ScaleInCooldown": 300,
    "ScaleOutCooldown": 60
  }'
```

---

### Task 4.2: DynamoDB Tables (40 Points)

**Objective:** Implement NoSQL database for sessions and caching.

**Table Design:**

| Table | Primary Key | Sort Key | GSI | Purpose |
|-------|------------|----------|-----|---------|
| Sessions | userId | sessionId | - | User sessions |
| Transactions | transactionId | - | userId-timestamp | Transaction cache |
| Accounts | accountId | - | userId | Account lookup |

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Table Creation | 15 | Proper schema, indexes |
| Auto Scaling | 10 | Read/Write capacity |
| Streams | 10 | DynamoDB Streams enabled |
| Encryption | 5 | KMS encryption enabled |

**Implementation:**

```bash
# Create DynamoDB Table with Auto Scaling
aws dynamodb create-table \
  --table-name fintech-sessions \
  --attribute-definitions \
    AttributeName=userId,AttributeType=S \
    AttributeName=sessionId,AttributeType=S \
  --key-schema \
    AttributeName=userId,KeyType=HASH \
    AttributeName=sessionId,KeyType=RANGE \
  --billing-mode PROVISIONED \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES \
  --sse-specification Enabled=true,SSEType=KMS,KMSMasterKeyId=$KMS_KEY_ID \
  --tags Key=Project,Value=FinTech Key=Environment,Value=Production

# Enable Auto Scaling for Reads
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --scalable-dimension dynamodb:table:ReadCapacityUnits \
  --resource-id table/fintech-sessions \
  --min-capacity 5 \
  --max-capacity 100

aws application-autoscaling put-scaling-policy \
  --service-namespace dynamodb \
  --scalable-dimension dynamodb:table:ReadCapacityUnits \
  --resource-id table/fintech-sessions \
  --policy-name read-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "DynamoDBReadCapacityUtilization"
    },
    "ScaleInCooldown": 60,
    "ScaleOutCooldown": 60
  }'

# Enable Auto Scaling for Writes
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --resource-id table/fintech-sessions \
  --min-capacity 5 \
  --max-capacity 100

aws application-autoscaling put-scaling-policy \
  --service-namespace dynamodb \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --resource-id table/fintech-sessions \
  --policy-name write-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "DynamoDBWriteCapacityUtilization"
    },
    "ScaleInCooldown": 60,
    "ScaleOutCooldown": 60
  }'
```

---

### Task 4.3: S3 Data Lake (30 Points)

**Objective:** Implement secure, compliant data storage.

**Bucket Structure:**

```
fintech-data-lake/
├── raw/
│   ├── transactions/
│   ├── logs/
│   └── events/
├── processed/
│   ├── daily-reports/
│   └── aggregations/
├── archive/
│   └── compliance/
└── analytics/
    └── ml-data/
```

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Bucket Creation | 5 | Proper naming, encryption |
| Lifecycle Policies | 10 | Intelligent tiering, transitions |
| Encryption | 5 | SSE-KMS, bucket key |
| Access Logging | 5 | S3 server access logs |
| Versioning & Replication | 5 | Versioning enabled, same-region replication |

**Implementation:**

```bash
# Create S3 bucket for data lake
BUCKET_NAME="fintech-data-lake-$(date +%s)"
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption with KMS
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "'$KMS_KEY_ID'"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable server access logging
LOG_BUCKET="fintech-s3-logs-$(date +%s)"
aws s3api create-bucket --bucket $LOG_BUCKET --region us-east-1

aws s3api put-bucket-logging \
  --bucket $BUCKET_NAME \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "'$LOG_BUCKET'",
      "TargetPrefix": "access-logs/"
    }
  }'

# Create folder structure
aws s3api put-object --bucket $BUCKET_NAME --key raw/transactions/
aws s3api put-object --bucket $BUCKET_NAME --key raw/logs/
aws s3api put-object --bucket $BUCKET_NAME --key raw/events/
aws s3api put-object --bucket $BUCKET_NAME --key processed/daily-reports/
aws s3api put-object --bucket $BUCKET_NAME --key processed/aggregations/
aws s3api put-object --bucket $BUCKET_NAME --key archive/compliance/
aws s3api put-object --bucket $BUCKET_NAME --key analytics/ml-data/

# Configure lifecycle policy for Intelligent-Tiering
aws s3api put-bucket-intelligent-tiering-configuration \
  --bucket $BUCKET_NAME \
  --id "EntireBucket" \
  --intelligent-tiering-configuration '{
    "Status": "Enabled",
    "Filter": {}
  }'

# Create lifecycle policy for transitions
aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration '{
    "Rules": [{
      "Id": "ArchiveOldData",
      "Status": "Enabled",
      "Prefix": "archive/",
      "Transitions": [{
        "Days": 90,
        "StorageClass": "STANDARD_IA"
      }, {
        "Days": 180,
        "StorageClass": "GLACIER"
      }, {
        "Days": 365,
        "StorageClass": "DEEP_ARCHIVE"
      }]
    }, {
      "Id": "DeleteOldVersions",
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }]
  }'

# Enable same-region replication (requires creating replication role first)
# Note: This is a simplified version - full replication setup requires IAM role creation
```

---

### Task 4.4: ElastiCache Redis (30 Points)

**Objective:** Implement high-performance caching with Redis.

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Redis Cluster | 15 | Multi-AZ, encrypted |
| Failover Config | 5 | Automatic failover enabled |
| Parameter Tuning | 5 | Optimized parameters |
| Security | 5 | Auth token, VPC security groups |

**Implementation:**

```bash
# Create ElastiCache Subnet Group
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name fintech-redis-subnets \
  --cache-subnet-group-description "Subnets for FinTech Redis cluster" \
  --subnet-ids $DB_SUBNET_A $DB_SUBNET_B

# Create ElastiCache Security Group
REDIS_SG=$(aws ec2 create-security-group \
  --group-name fintech-redis-sg \
  --description "Security group for ElastiCache Redis" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Allow ECS tasks to access Redis
aws ec2 authorize-security-group-ingress \
  --group-id $REDIS_SG \
  --protocol tcp \
  --port 6379 \
  --source-group $ECS_SG

# Create ElastiCache Redis Cluster
aws elasticache create-replication-group \
  --replication-group-id fintech-redis-cluster \
  --description "FinTech Redis cluster for caching" \
  --engine redis \
  --engine-version 7.0 \
  --node-type cache.r6g.large \
  --num-cache-clusters 2 \
  --cache-subnet-group-name fintech-redis-subnets \
  --security-group-ids $REDIS_SG \
  --at-rest-encryption-enabled \
  --transit-encryption-enabled \
  --auth-token "$REDIS_AUTH_TOKEN" \
  --automatic-failover-enabled \
  --multi-az-enabled \
  --snapshot-retention-limit 7 \
  --tags Key=Project,Value=FinTech Key=Environment,Value=Production
```

---

### Task 4.5: Secrets Manager Configuration (30 Points)

**Objective:** Securely manage application secrets and credentials.

**Required Secrets:**

| Secret Name | Type | Purpose |
|------------|------|---------|
| fintech/db-credentials | Credentials | Aurora database credentials |
| fintech/api-keys | String | API keys for external services |
| fintech/redis-auth | String | ElastiCache Redis auth token |
| fintech/encryption-key | Binary | Application encryption keys |

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Secret Creation | 10 | 4+ secrets configured |
| Rotation | 10 | Automatic rotation enabled |
| Access Control | 5 | IAM policies for secrets |
| Integration | 5 | ECS integration |

**Implementation:**

```bash
# Note: Database credentials secret already created in Task 4.1
# To enable automatic rotation, use AWS managed rotation:
# aws secretsmanager enable-secret-rotation \
#   --secret-id fintech/db-credentials \
#   --rotation-rules AutomaticallyAfterDays=30

# Create secret for API keys
aws secretsmanager create-secret \
  --name fintech/api-keys \
  --description "API keys for external services" \
  --secret-string '{
    "stripe_api_key": "sk_live_xxxxx",
    "sendgrid_api_key": "SG.xxxxx"
  }' \
  --kms-key-id $KMS_KEY_ID

# Generate Redis auth token
REDIS_AUTH_TOKEN=$(openssl rand -base64 32)

# Create secret for Redis auth token
aws secretsmanager create-secret \
  --name fintech/redis-auth \
  --description "ElastiCache Redis authentication token" \
  --secret-string $REDIS_AUTH_TOKEN \
  --kms-key-id $KMS_KEY_ID

# Grant ECS task execution role access to secrets
aws iam put-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-name SecretsManagerAccess \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:$ACCOUNT_ID:secret:fintech/*"
      ]
    }]
  }'
```

---

## Category 5: Observability (70 Points)

### Task 5.1: CloudWatch Configuration (40 Points)

**Objective:** Implement comprehensive monitoring.

**Required Dashboards:**

1. **Executive Dashboard** - High-level KPIs
2. **Operations Dashboard** - Service health
3. **Cost Dashboard** - Spending trends

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Custom Metrics | 10 | 10+ custom metrics |
| Dashboards | 15 | 3 comprehensive dashboards |
| Alarms | 10 | 20+ alarms with actions |
| Logs Insights | 5 | Saved queries |

**Implementation:**

```bash
# Create comprehensive CloudWatch Dashboard
aws cloudwatch put-dashboard \
  --dashboard-name FinTech-Operations \
  --dashboard-body '{
    "widgets": [
      {
        "type": "metric",
        "x": 0, "y": 0, "width": 8, "height": 6,
        "properties": {
          "title": "Transaction Processing Rate",
          "metrics": [
            ["FinTech", "TransactionsProcessed", {"stat": "Sum", "period": 60}],
            [".", "TransactionsFailed", {"stat": "Sum", "period": 60}]
          ],
          "region": "us-east-1"
        }
      },
      {
        "type": "metric",
        "x": 8, "y": 0, "width": 8, "height": 6,
        "properties": {
          "title": "API Latency (p99)",
          "metrics": [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "app/fintech-alb", {"stat": "p99"}]
          ]
        }
      },
      {
        "type": "metric",
        "x": 16, "y": 0, "width": 8, "height": 6,
        "properties": {
          "title": "Database Performance",
          "metrics": [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", "fintech-cluster"],
            [".", "DatabaseConnections", ".", "."],
            [".", "AuroraReplicaLag", ".", "."]
          ]
        }
      },
      {
        "type": "alarm",
        "x": 0, "y": 6, "width": 24, "height": 4,
        "properties": {
          "title": "Active Alarms",
          "alarms": [
            "arn:aws:cloudwatch:us-east-1:ACCOUNT:alarm:high-error-rate",
            "arn:aws:cloudwatch:us-east-1:ACCOUNT:alarm:high-latency",
            "arn:aws:cloudwatch:us-east-1:ACCOUNT:alarm:db-connections",
            "arn:aws:cloudwatch:us-east-1:ACCOUNT:alarm:fraud-detection"
          ]
        }
      }
    ]
  }'

# Create Critical Alarms
aws cloudwatch put-metric-alarm \
  --alarm-name fintech-transaction-failures \
  --alarm-description "High transaction failure rate" \
  --metric-name TransactionsFailed \
  --namespace FinTech \
  --statistic Sum \
  --period 300 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:$ACCOUNT_ID:fintech-alerts \
  --ok-actions arn:aws:sns:us-east-1:$ACCOUNT_ID:fintech-alerts \
  --treat-missing-data notBreaching
```

---

### Task 5.2: X-Ray Tracing (30 Points)

**Objective:** Implement distributed tracing.

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Service Map | 10 | All services traced |
| Custom Segments | 10 | Business logic tracing |
| Sampling Rules | 5 | Custom sampling rules |
| Insights | 5 | X-Ray Insights enabled |

---

## Category 6: Cost Optimization (75 Points)

### Task 6.1: Reserved Capacity (25 Points)

**Objective:** Implement cost-effective capacity reservations.

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Savings Plans | 10 | Compute SP purchased |
| Reserved Instances | 10 | RDS/ElastiCache RIs |
| Coverage Analysis | 5 | 70%+ coverage target |

---

### Task 6.2: Cost Monitoring (25 Points)

**Objective:** Implement comprehensive cost visibility.

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Budgets | 10 | Monthly + per-service |
| Cost Anomaly Detection | 10 | Enabled and configured |
| Reports | 5 | CUR to S3 + Athena |

---

### Task 6.3: Optimization Recommendations (25 Points)

**Objective:** Identify and implement optimizations.

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Right-Sizing | 10 | Implemented recommendations |
| Spot Usage | 10 | 60%+ ECS tasks on Fargate Spot |
| Storage Tiering | 5 | S3 Intelligent-Tiering |

---

## Category 7: High Availability & DR (75 Points)

### Task 7.1: High Availability & Backup (40 Points)

**Objective:** Implement high availability within single region with backup strategy.

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Multi-AZ Deployment | 15 | All services multi-AZ |
| Backup Strategy | 15 | Automated backups configured |
| Data Replication | 10 | Multi-AZ replication within region |

---

### Task 7.2: Backup & Recovery Testing (35 Points)

**Objective:** Validate backup and recovery procedures.

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Backup Runbook | 10 | Complete documentation |
| Recovery Test | 15 | Successful restore execution |
| Recovery Validation | 10 | Successful recovery test completed |

---

## Category 8: Documentation & Presentation (100 Bonus Points)

### Task 8.1: Architecture Documentation (50 Points)

**Required Documents:**

| Document | Points | Contents |
|----------|--------|----------|
| Architecture Decision Records | 15 | 10+ ADRs |
| High-Level Design | 15 | System diagrams |
| Runbooks | 20 | Operational procedures |

---

### Task 8.2: Presentation (50 Points)

**Scoring Rubric:**

| Criteria | Points | Requirements |
|----------|--------|--------------|
| Demo Quality | 20 | Working demonstration |
| Technical Depth | 15 | Deep understanding shown |
| Q&A Handling | 15 | Confident responses |

---

## 📊 Final Scoring Summary

### Score Calculation

| Category | Max Points | Your Score |
|----------|------------|------------|
| 1. Foundation & Organization | 75 | ___ |
| 2. Networking | 40 | ___ |
| 3. Compute & Containers | 110 | ___ |
| 4. Data Layer | 180 | ___ |
| 5. Observability | 70 | ___ |
| 6. Cost Optimization | 75 | ___ |
| 7. High Availability & DR | 75 | ___ |
| **Core Total** | **625** | **___** |
| 8. Documentation (Bonus) | 100 | ___ |
| **Grand Total** | **725** | **___** |

### Grading Scale

| Grade | Score Range | Description |
|-------|-------------|-------------|
| **A+** | 560-725 | Exceptional - Expert level |
| **A** | 510-559 | Excellent - Production ready |
| **A-** | 460-509 | Very Good - Minor improvements |
| **B+** | 410-459 | Good - Some gaps |
| **B** | 375-409 | Satisfactory - Needs work |
| **B-** | 340-374 | Passing - Minimum acceptable |
| **C** | 300-339 | Below expectations |
| **F** | <300 | Failing - Major rework needed |

---

## 🎓 Completion Certificate Requirements

To receive the course completion certificate:

1. ✅ Score 375+ points (60% of core total)
2. ✅ Demonstrate working backup and restore
3. ✅ Present architecture to panel

---

## 📚 Resources

### AWS Documentation
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Amazon ECS](https://docs.aws.amazon.com/ecs/)
- [Amazon ElastiCache](https://docs.aws.amazon.com/elasticache/)

### Tools
- AWS CLI v2
- Docker

---

## 🚀 Good Luck!

This capstone project represents the culmination of your AWS learning journey. Take your time, follow best practices, and build something you're proud of!

**Remember:** Quality > Speed. A well-architected solution is worth more than a rushed implementation.
