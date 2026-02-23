# Operational Runbooks

## Runbook 01: Database Backup and Recovery
### Background
The Aurora PostgreSQL cluster utilizes automated backups with a 35-day retention period.

### Manual Snapshot
To create a manual snapshot:
```bash
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier fintech-cluster \
  --db-cluster-snapshot-identifier fintech-cluster-manual-$(date +%Y%m%d)
```

### Point-in-Time Recovery (PITR)
To restore to a specific point in time:
```bash
aws rds restore-db-cluster-to-point-in-time \
  --source-db-cluster-identifier fintech-cluster \
  --target-db-cluster-identifier fintech-cluster-restored \
  --restore-to-time 2026-01-28T12:00:00Z
```

## Runbook 02: Deploying Application Updates
### Process
1.  Build new Docker image: `docker build -t fintech-api:v2 .`
2.  Authenticate with ECR: `aws ecr get-login-password --region us-east-1 | docker login ...`
3.  Tag and Push: `docker push $ECR_URI:v2`
4.  Update ECS Service:
```bash
aws ecs update-service --cluster fintech-cluster --service fintech-api-service --force-new-deployment
```

## Runbook 03: Scaling Infrastructure
### ECS Service
The service is configured with target tracking (70% CPU). To manually scale:
```bash
aws ecs update-service --cluster fintech-cluster --service fintech-api-service --desired-count 5
```

### Aurora Read Replicas
Aurora auto-scaling is enabled for read replicas. To manually add a reader:
```bash
aws rds create-db-instance \
  --db-instance-identifier fintech-reader-2 \
  --db-cluster-identifier fintech-cluster \
  --db-instance-class db.t4g.medium \
  --engine aurora-postgresql
```
