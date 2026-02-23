# AWS FinTech Capstone Project - Services Documentation

This document explains all AWS services used in this project, their purpose, and why they are essential for building a secure, scalable FinTech application.

## Compute & Container Services

### 1. Amazon ECS (Elastic Container Service)
*   **Purpose**: Container orchestration platform for running the FinTech API.
*   **Why It Matters**:
    *   Runs our containerized Python application.
    *   Automatically scales containers based on demand.
    *   Manages container lifecycle and health checks.

### 2. AWS Fargate
*   **Purpose**: Serverless compute engine for containers.
*   **Why It Matters**:
    *   Removes the overhead of managing EC2 instances.
    *   Pay-as-you-go pricing for container resources.
    *   Automatic patching and security updates.

### 3. Amazon ECR (Elastic Container Registry)
*   **Purpose**: Private Docker container registry.
*   **Why It Matters**:
    *   Secure storage for application Docker images.
    *   Automatic vulnerability scanning.
    *   Seamless integration with ECS.

## Database Services

### 4. Amazon Aurora PostgreSQL
*   **Purpose**: Relational database for transactional data.
*   **Why It Matters**:
    *   ACID compliance for financial data integrity.
    *   Multi-AZ replication with automatic failover.
    *   Continuous backups and point-in-time recovery.

### 5. Amazon DynamoDB
*   **Purpose**: NoSQL database for session management.
*   **Why It Matters**:
    *   Ultra-low latency access for high-concurrency user sessions.
    *   Serverless scaling to handle traffic bursts.

### 6. Amazon ElastiCache (Redis)
*   **Purpose**: In-memory caching layer.
*   **Why It Matters**:
    *   Sub-millisecond latency for frequent data access.
    *   Reduces load on the primary Aurora database.

## Networking & Security

### 7. Amazon VPC (Virtual Private Cloud)
*   **Purpose**: Isolated network environment.
*   **Architecture**:
    *   Multi-AZ setup with Public, Private App, and Private DB subnets.
    *   Network ACLs and Security Groups provide defense-in-depth.

### 8. Application Load Balancer (ALB)
*   **Purpose**: Distributes traffic across container tasks.
*   **Features**: SSL/TLS termination, path-based routing, and target health monitoring.

### 9. VPC Endpoints
*   **Purpose**: Private connections to AWS services via the AWS backbone network.
*   **Endpoints**: S3, DynamoDB, ECR, Secrets Manager, and CloudWatch Logs.

### 10. AWS Secrets Manager & KMS
*   **Purpose**: Secure credential storage and encryption key management.
*   **Security**: Ensures sensitive data like DB passwords and API keys are never hardcoded and are always encrypted at rest.

## Monitoring & Compliance

### 11. Amazon CloudWatch & X-Ray
*   **Purpose**: Centralized logging, metrics, and distributed tracing.
*   **Visibility**: Custom "FinTech-Operations" dashboard provides visibility across all stack layers.

### 12. AWS CloudTrail & AWS Config
*   **Purpose**: Audit logging and configuration tracking for compliance (SOC 2 ready).
*   **Governance**: Continuously evaluates resources against security best practices.
