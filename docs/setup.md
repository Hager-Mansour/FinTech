# Developer Setup & Deployment Guide

This guide provides the necessary steps to set up a local development environment and deploy the infrastructure to AWS.

## 💻 Local Development

### Application (FastAPI)
1.  **Environment Setup**:
    ```bash
    cd app/
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```
2.  **Running Locally**:
    ```bash
    uvicorn main:app --reload --host 0.0.0.0 --port 8080
    ```
    *Note: Local execution requires local PostgreSQL and Redis or mock connections.*

### Docker
Build and test the container locally:
```bash
docker build -t fintech-api .
docker run -p 8080:8080 fintech-api
```

## ☁️ AWS Infrastructure Deployment

### Terraform Organization
The infrastructure is split into logical files:
*   `vpc.tf`: Networking base.
*   `ecs_cluster.tf` & `ecs_service.tf`: Compute layer.
*   `data_layer.tf` & `rds.tf`: Storage and Databases.
*   `compliance.tf`: Audit and Governance.
*   `observability.tf`: Monitoring and Alarms.

### Execution Plan
1.  **Validate**: `terraform validate`
2.  **Plan**: `terraform plan`
3.  **Apply**: `terraform apply -auto-approve`

## 📦 Container Workflow (CI/CD)
To push new versions to ECR:
1.  **ECR Login**:
    ```bash
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url)
    ```
2.  **Tag & Push**:
    ```bash
    docker tag fintech-api:latest $(terraform output -raw ecr_repository_url):latest
    docker push $(terraform output -raw ecr_repository_url):latest
    ```
3.  **Update Service**:
    ```bash
    aws ecs update-service --cluster fintech-cluster --service fintech-api-service --force-new-deployment
    ```
