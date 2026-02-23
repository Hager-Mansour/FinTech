# FinTech Global Platform - DevOps & Infrastructure

![Architecture](https://img.shields.io/badge/Architecture-AWS%20Multi--AZ-orange)
![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-blueviolet)
![Compliance](https://img.shields.io/badge/Compliance-SOC2%20Ready-green)

A production-grade, highly available financial technology platform built on AWS using Infrastructure as Code (Terraform). This project implements a secure, scalable, and observable microservices architecture designed for high-concurrency transactional workloads.

## 🚀 Project Overview

The FinTech Global Platform is designed to handle high transaction volumes with zero-trust security and multi-AZ resilience. It utilizes a containerized backend, managed relational and NoSQL databases, and an integrated observability suite.

### Key Features
*   **Multi-AZ VPC**: 6 subnets across 2 Availability Zones with dedicated NAT Gateways.
*   **Serverless Compute**: Amazon ECS Fargate with auto-scaling (Target Tracking at 70% CPU).
*   **Resilient Data Layer**: Aurora PostgreSQL (transactions), DynamoDB (sessions), and ElastiCache Redis (cache).
*   **Enterprise Security**: KMS encryption at rest, Secrets Manager, and VPC Endpoints for private traffic.
*   **Audit & Compliance**: CloudTrail and AWS Config for continuous governance.
*   **End-to-End Observability**: CloudWatch dashboards, multi-layer alarms, and X-Ray tracing.

## 🏗 Architecture

The platform follows a three-tier architecture spread across multiple Availability Zones to ensure high availability (>99.9%).

*   **Web Tier**: Application Load Balancer in public subnets.
*   **App Tier**: ECS Fargate tasks in private app subnets.
*   **Data Tier**: Aurora, DynamoDB, and Redis in private database subnets.

Refer to the **[High-Level Design (HLD)](docs/hld.md)** for detailed diagrams.

## 📂 Project Structure

```text
├── app/               # FastAPI Application source code
├── terraform/         # Infrastructure as Code
├── docs/              # Detailed Technical Documentation
│   ├── adr.md         # Architecture Decision Records
│   ├── services.md    # Detailed AWS Service breakdown
│   ├── runtime_flow.md # Request & Deployment flows
│   ├── runbooks.md    # Operational procedures
│   └── ha_backup.md   # HA & Disaster Recovery Strategy
└── README.md          # Entry point
```

## 🛠 Getting Started

### Prerequisites
*   [Terraform](https://www.terraform.io/downloads) (>= 1.5.0)
*   [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
*   [Docker](https://www.docker.com/) for building application images

### Deployment
1.  **Initialize Infrastructure**:
    ```bash
    cd terraform/
    terraform init
    terraform apply
    ```
2.  **Deploy Application**:
    Build and push the Docker image to ECR as detailed in the **[Runbooks](docs/runbooks.md)**.

## 🔐 Security & Compliance
This project enforces:
*   Encrypted storage (S3, RDS, DDB, Secrets).
*   Least-privilege IAM roles.
*   Private network isolation (no public IP for tasks/databases).
*   Automatic credential rotation via Secrets Manager.

## 📊 Monitoring
Logs and metrics are centralized in **CloudWatch**.
*   **Dashboard**: `FinTech-Operations`
*   **Alarms**: SNS notifications for high CPU, memory, latency, and unhealthy targets.

## 📄 Documentation Indices
*   **[ADRs](docs/adr.md)**: Why we made these technical choices.
*   **[Services](docs/services.md)**: Deep dive into the AWS stack.
*   **[Runtime Flow](docs/runtime_flow.md)**: How requests and deployments execute.
*   **[Operations](docs/runbooks.md)**: How to scale, backup, and recover the system.
*   **[HA & Backup](docs/ha_backup.md)**: Resilience strategy.
