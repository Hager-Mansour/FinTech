# High-Level Design (HLD) - FinTech Global Platform

## System Architecture

```mermaid
graph TD
    subgraph "External"
        User[Users]
        CF[CloudFront]
    end

    subgraph "Public Subnets"
        ALB[Application Load Balancer]
        NAT[NAT Gateways]
    end

    subgraph "Private App Subnets"
        ECS[ECS Tasks - Fargate]
    end

    subgraph "Private Data Subnets"
        RDS[(Aurora PostgreSQL)]
        Redis[(ElastiCache Redis)]
    end

    subgraph "Other Regional Services"
        S3[S3 Data Lake]
        DDB[(DynamoDB)]
        SM[Secrets Manager]
        CW[CloudWatch]
    end

    User --> CF
    CF --> ALB
    ALB --> ECS
    ECS --> RDS
    ECS --> Redis
    ECS --> DDB
    ECS --> S3
    ECS --> SM
    ECS --> CW
    NAT -.-> ECS
```

## Security Design
- **Network Segmentation**: Public, Private App, and Private Data subnets.
- **Encryption**: KMS-based encryption at rest for S3, RDS, DynamoDB, and Secrets.
- **IAM**: Least-privilege roles for ECS Task Execution and Tasks.
- **Compliance**: Lifecycle policies for S3 to meet 7-year retention requirements.
