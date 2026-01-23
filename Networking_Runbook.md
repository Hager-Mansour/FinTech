# AWS Networking & Security Runbook

**Category:** 2 - Networking
**Project:** FinTech Global Platform
**Target Environment:** Production (`us-east-1`)
**Version:** 2.0 (Strict Compliance)
**Last Updated:** 2026-01-23
**Author:** Cloud Architecture Team

---

## 1. VPC Architecture Setup

**Objective:** Establish the isolated logical network container.

### 1.1 Create VPC
**CLI Command:**
```bash
# 1. Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=fintech-prod-vpc},{Key=Environment,Value=Production},{Key=Project,Value=FinTechGlobal}]' \
  --query 'Vpc.VpcId' --output text)

# 2. Enable DNS Hostnames & Resolution (REQUIRED)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}'
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support '{"Value":true}'
```

**Validation:**
```bash
aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].{Cidr:CidrBlock,DNS:InstanceTenancy,Tags:Tags}'
```
*Expected Output:* `Cidr: 10.0.0.0/16`, DNS enabled, Tags present.

---

## 2. Subnet Architecture (Multi-AZ)

**Objective:** Create 3-tier subnets across 2 Availability Zones (`us-east-1a`, `us-east-1b`).

### 2.1 Create Subnets
**CLI Commands:**
```bash
# Variables
AZ_A="us-east-1a"
AZ_B="us-east-1b"

# --- Public Subnets ---
PUB_SUB_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone $AZ_A --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-AZ-A},{Key=Type,Value=Public}]' --query 'Subnet.SubnetId' --output text)
PUB_SUB_B=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone $AZ_B --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-AZ-B},{Key=Type,Value=Public}]' --query 'Subnet.SubnetId' --output text)

# --- Private Application Subnets ---
APP_SUB_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.11.0/24 --availability-zone $AZ_A --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=App-AZ-A},{Key=Type,Value=Private}]' --query 'Subnet.SubnetId' --output text)
APP_SUB_B=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.12.0/24 --availability-zone $AZ_B --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=App-AZ-B},{Key=Type,Value=Private}]' --query 'Subnet.SubnetId' --output text)

# --- Private Database Subnets ---
DB_SUB_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.21.0/24 --availability-zone $AZ_A --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DB-AZ-A},{Key=Type,Value=Database}]' --query 'Subnet.SubnetId' --output text)
DB_SUB_B=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.22.0/24 --availability-zone $AZ_B --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DB-AZ-B},{Key=Type,Value=Database}]' --query 'Subnet.SubnetId' --output text)
```

**Validation:**
```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone}'
```
*Expected Output:* List of 6 subnets with correct CIDRs and AZs.

---

## 3. Internet Connectivity

**Objective:** Enable public internet access for Public Subnets.

### 3.1 Internet Gateway (IGW)
**CLI Commands:**
```bash
# 1. Create IGW
IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=fintech-igw}]' --query 'InternetGateway.InternetGatewayId' --output text)

# 2. Attach to VPC (CRITICAL STEP)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
```

### 3.2 Public Route Table
**CLI Commands:**
```bash
# 1. Create Route Table
RT_PUB=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public-RT}]' --query 'RouteTable.RouteTableId' --output text)

# 2. Create Route (0.0.0.0/0 -> IGW)
aws ec2 create-route --route-table-id $RT_PUB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# 3. Associate Public Subnets (CRITICAL STEP)
aws ec2 associate-route-table --subnet-id $PUB_SUB_A --route-table-id $RT_PUB
aws ec2 associate-route-table --subnet-id $PUB_SUB_B --route-table-id $RT_PUB
```

---

## 4. NAT Gateway High Availability

**Objective:** Enable outbound internet for Private Subnets with AZ redundancy.

### 4.1 Create NAT Gateways
**CLI Commands:**
```bash
# 1. Allocate Elastic IPs
EIP_A_ID=$(aws ec2 allocate-address --domain vpc --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=nat-eip-a}]' --query 'AllocationId' --output text)
EIP_B_ID=$(aws ec2 allocate-address --domain vpc --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=nat-eip-b}]' --query 'AllocationId' --output text)

# 2. Create NAT Gateways (One per AZ)
NAT_GW_A=$(aws ec2 create-nat-gateway --subnet-id $PUB_SUB_A --allocation-id $EIP_A_ID --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=nat-gw-a}]' --query 'NatGateway.NatGatewayId' --output text)
NAT_GW_B=$(aws ec2 create-nat-gateway --subnet-id $PUB_SUB_B --allocation-id $EIP_B_ID --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=nat-gw-b}]' --query 'NatGateway.NatGatewayId' --output text)

# 3. Wait for Available State
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_A $NAT_GW_B
```

---

## 5. Route Tables Architecture (Private)

**Objective:** Route private traffic to the *local* AZ's NAT Gateway to minimize latency and cross-AZ costs.

### 5.1 Private Application Route Tables
**CLI Commands:**
```bash
# --- AZ-A Route Table ---
RT_APP_A=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-App-A-RT}]' --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RT_APP_A --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_A
aws ec2 associate-route-table --subnet-id $APP_SUB_A --route-table-id $RT_APP_A

# --- AZ-B Route Table ---
RT_APP_B=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-App-B-RT}]' --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RT_APP_B --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_B
aws ec2 associate-route-table --subnet-id $APP_SUB_B --route-table-id $RT_APP_B
```

### 5.2 Private Database Route Table
**CLI Commands:**
```bash
# Create Isolated Route Table (No Internet Route)
RT_DB=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-DB-RT}]' --query 'RouteTable.RouteTableId' --output text)

# Associate DB Subnets
aws ec2 associate-route-table --subnet-id $DB_SUB_A --route-table-id $RT_DB
aws ec2 associate-route-table --subnet-id $DB_SUB_B --route-table-id $RT_DB
```

---

## 6. VPC Endpoints

**Objective:** Secure, private connectivity to AWS services.

### 6.1 Gateway Endpoints (Free)
**CLI Commands:**
```bash
# S3
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID --service-name com.amazonaws.us-east-1.s3 --vpc-endpoint-type Gateway --route-table-ids $RT_APP_A $RT_APP_B $RT_DB

# DynamoDB
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID --service-name com.amazonaws.us-east-1.dynamodb --vpc-endpoint-type Gateway --route-table-ids $RT_APP_A $RT_APP_B $RT_DB
```

### 6.2 Interface Endpoints (PrivateLink)
**Prerequisite:** Security Group for Endpoints.
```bash
# Create SG
SG_VPCE=$(aws ec2 create-security-group --group-name vpce-sg --description "VPC Endpoints SG" --vpc-id $VPC_ID --output text --query GroupId)
aws ec2 authorize-security-group-ingress --group-id $SG_VPCE --protocol tcp --port 443 --cidr 10.0.0.0/16
```

**Creation Commands (Private DNS Enabled):**
```bash
# ECR API and DKR
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID --service-name com.amazonaws.us-east-1.ecr.api --vpc-endpoint-type Interface --subnet-ids $APP_SUB_A $APP_SUB_B --security-group-ids $SG_VPCE --private-dns-enabled
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID --service-name com.amazonaws.us-east-1.ecr.dkr --vpc-endpoint-type Interface --subnet-ids $APP_SUB_A $APP_SUB_B --security-group-ids $SG_VPCE --private-dns-enabled

# Secrets Manager
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID --service-name com.amazonaws.us-east-1.secretsmanager --vpc-endpoint-type Interface --subnet-ids $APP_SUB_A $APP_SUB_B --security-group-ids $SG_VPCE --private-dns-enabled

# Systems Manager (SSM)
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID --service-name com.amazonaws.us-east-1.ssm --vpc-endpoint-type Interface --subnet-ids $APP_SUB_A $APP_SUB_B --security-group-ids $SG_VPCE --private-dns-enabled
```

---

## 7. Network Security Controls

### 7.1 Security Groups (Least Privilege)
**CLI Commands:**
```bash
# 1. ALB SG (Public Inbound)
SG_ALB=$(aws ec2 create-security-group --group-name alb-sg --description "Public ALB" --vpc-id $VPC_ID --output text --query GroupId)
aws ec2 authorize-security-group-ingress --group-id $SG_ALB --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ALB --protocol tcp --port 443 --cidr 0.0.0.0/0

# 2. ECS SG (From ALB only)
SG_ECS=$(aws ec2 create-security-group --group-name ecs-apps-sg --description "ECS Application Tasks" --vpc-id $VPC_ID --output text --query GroupId)
aws ec2 authorize-security-group-ingress --group-id $SG_ECS --protocol tcp --port 8080 --source-group $SG_ALB

# 3. Database SG (From ECS only)
SG_DB=$(aws ec2 create-security-group --group-name database-sg --description "RDS Aurora" --vpc-id $VPC_ID --output text --query GroupId)
aws ec2 authorize-security-group-ingress --group-id $SG_DB --protocol tcp --port 5432 --source-group $SG_ECS

# 4. Redis SG (From ECS only)
SG_REDIS=$(aws ec2 create-security-group --group-name redis-sg --description "ElastiCache Redis" --vpc-id $VPC_ID --output text --query GroupId)
aws ec2 authorize-security-group-ingress --group-id $SG_REDIS --protocol tcp --port 6379 --source-group $SG_ECS
```

### 7.2 VPC Flow Logs
**CLI Commands:**
```bash
# Create Log Group
aws logs create-log-group --log-group-name /aws/vpc/fintech-flow-logs

# Enable Flow Logs (Requires IAM Role ARN - replace variable)
aws ec2 create-flow-logs --resource-type VPC --resource-ids $VPC_ID --traffic-type ALL \
  --log-destination-type cloud-watch-logs --log-destination arn:aws:logs:us-east-1:<ACC_ID>:log-group:/aws/vpc/fintech-flow-logs \
  --deliver-logs-permission-arn <IAM_ROLE_ARN>
```

### 7.3 Network ACL Baseline
*   **Public Subnets NACL:** Allow Inbound TCP 80/443 (Internet), Allow Ephemeral (1024-65535).
*   **Private Subnets NACL:** Deny 0.0.0.0/0 Inbound, Allow VPC CIDR Inbound.

---

## 8. Validation & Testing Strategies

| Component | Test Command | Destination | Expected Result |
|:--- |:--- |:--- |:--- |
| **Public Subnet** | `ping google.com` | Internet | Reply (via IGW) |
| **Private App** | `ping google.com` | Internet | Reply (via NAT) |
| **Private DB** | `ping google.com` | Internet | Timeout (Isolated) |
| **Endpoint** | `nslookup s3.us-east-1.amazonaws.com` | Internal IP | AWS Private IP |
| **Endpoint** | `aws s3 ls --region us-east-1` | S3 | Bucket List |
| **Inter-AZ** | `ping 10.0.12.x` | AZ-B Instance | Reply (from AZ-A) |

---

## 9. High Availability (HA) Behavior

### 9.1 Availability Zone Failure
-   **Scenario:** AWS AZ `us-east-1a` goes offline.
-   **Behavior:**
    -   ALB Health Checks detect AZ-A targets as unhealthy.
    -   ALB immediately shifts 100% of traffic to healthy targets in **AZ-B**.
    -   RDS Multi-AZ triggers automatic failover to the Standby Replica in AZ-B (DNS record updates automatically).
    -   App services continue running with reduced capacity until Auto Scaling adds nodes to AZ-B.

### 9.2 NAT Gateway Failure
-   **Scenario:** NAT Gateway in AZ-A fails.
-   **Impact:** Instances in `App-AZ-A` cannot reach the internet (e.g., for patching or 3rd party APIs). Internal traffic remains unaffected.
-   **Behavior:** Traffic does NOT automatically failover to NAT-B because route tables are hardcoded to NAT-A. (See Rollback/Recovery).

---

## 10. Rollback & Recovery Procedures

### 10.1 NAT Gateway Replacement (Recovery)
If `nat-gw-a` is deleted or fails permanently:
1.  **Create New NAT:**
    ```bash
    NEW_NAT_ID=$(aws ec2 create-nat-gateway --subnet-id $PUB_SUB_A --allocation-id $EIP_A_ID ...)
    ```
2.  **Update Route Table:**
    ```bash
    aws ec2 replace-route --route-table-id $RT_APP_A --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NEW_NAT_ID
    ```

### 10.2 Endpoint Removal Rollback
If a faulty VPC Endpoint blocks access:
1.  **Delete Endpoint:**
    ```bash
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids <VPCE_ID>
    ```
2.  **Verification:** Traffic falls back to standard routes (NAT Gateway) if routes exist. Note: Private DNS must be disabled on the service to revert DNS resolution to public IPs.

---

## 11. Post Deployment Checklist

-   [ ] VPC active with `enableDnsHostnames` = true.
-   [ ] 6 Subnets verified (2 Public, 2 Pvt-App, 2 Pvt-DB).
-   [ ] IGW attached to VPC.
-   [ ] Public Subnets associated with Route Table pointing to IGW.
-   [ ] 2 NAT Gateways active (one per AZ).
-   [ ] Private-App Route Tables point to *local* AZ NAT Gateway.
-   [ ] Private-DB Route Table has *no* route to 0.0.0.0/0.
-   [ ] S3 & DynamoDB Gateway Endpoints listed in Route Tables.
-   [ ] Interface Endpoints (ECR, Secrets, SSM) active with `PrivateDNS`.
-   [ ] Security Groups for Redis, DB, and ECS reference each other (Chained).
-   [ ] Flow Logs verified in CloudWatch Log Group.
