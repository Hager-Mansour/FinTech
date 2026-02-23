# High Availability & Backup Strategy

## High Availability (HA)
The FinTech Global Platform is designed for 99.9% availability within the `us-east-1` region.

### Component Redundancy
- **Networking**: VPC spans 2 Availability Zones. NAT Gateways are deployed in each public subnet.
- **Compute**: ECS Fargate service is configured with a minimum of 3 tasks distributed across 2 AZs.
- **Load Balancing**: Application Load Balancer (ALB) is multi-AZ by default.
- **Database (Relational)**: Aurora PostgreSQL is configured in a Multi-AZ cluster with one writer and one reader. Storage is replicated 6-ways across 3 AZs.
- **Database (NoSQL)**: DynamoDB is multi-AZ regional service.
- **Caching**: ElastiCache Redis is configured with a replication group, multi-AZ enabled, and automatic failover.

## Backup Strategy
To meet the 7-year data retention and SOC 2 compliance requirements.

### Databases
- **Aurora**: Automated backups with 35-day retention. Point-in-time recovery (PITR) enabled.
- **DynamoDB**: Point-in-time recovery (PITR) enabled for the `sessions` table.

### Object Storage (S3 Data Lake)
- **Versioning**: Enabled on all buckets to protect against accidental deletes.
- **Replication**: Same-region replication (SRR) can be configured for critical prefixes.
- **Lifecycle**:
    - 0-90 days: S3 Standard
    - 90-180 days: S3 Standard-IA
    - 180-365 days: S3 Glacier Flexible Retrieval
    - 1-7 years: S3 Glacier Deep Archive

### Infrastructure
- **Terraform**: All infrastructure is defined as code, allowing for rapid recreation in a different region if necessary (DR).
