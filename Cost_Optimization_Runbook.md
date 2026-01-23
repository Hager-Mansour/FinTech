# AWS Cost Optimization Runbook

**Category:** 6 – Cost Optimization
**Project:** FinTech Global Platform
**Region:** `us-east-1`
**Compliance:** SOC2 + PCI DSS
**Target Score:** 75/75 (Full Coverage)
**Version:** 2.0 (Strict Compliance)
**Last Updated:** 2026-01-23
**Author:** Cloud FinOps Team

---

## 6.1 Reserved Capacity (25 Points)

**Objective:** Achieve >70% coverage for steady-state workloads using commitment-based discounts.

### 1) Compute Savings Plans (10 Points)
**Commitment:** 1 Year, No Upfront.
**Scope:** Fargate, Lambda, EC2.

**A. Generate Recommendations**
```bash
aws ce get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP \
  --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT \
  --lookback-period-in-days THIRTY_DAYS \
  --query "Metadata.GenerationTimestamp"
```

**B. Purchase Savings Plan**
```bash
# Example Commitment: $0.50/hour (Replace with value from recommendation)
aws savingsplans create-savings-plan \
  --savings-plan-offering-id <OFFERING_ID> \
  --commitment 0.50 \
  --tags Key=Project,Value=FinTechGlobal Key=Environment,Value=Production
```

**C. Validation (Coverage > 70%)**
```bash
aws ce get-savings-plans-coverage \
  --time-period Start=$(date -d "-30 days" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --query "SavingsPlansCoverages[].Coverage.CoveragePercentage"
```

### 2) Reserved Instances (10 Points)

**A. Aurora PostgreSQL Reserved Instances**
*   **Engine:** `aurora-postgresql`
*   **Type:** `db.r6g.large` (2 Instances: Writer + Reader)
*   **Term:** 1 Year No Upfront

```bash
aws rds purchase-reserved-db-instances-offering \
  --reserved-db-instances-offering-id <OFFERING_ID> \
  --db-instance-count 2 \
  --tags Key=Project,Value=FinTechGlobal
```

**B. ElastiCache Reserved Nodes**
*   **Type:** `cache.t4g.medium` (1 Node, Multi-AZ)
*   **Term:** 1 Year No Upfront

```bash
aws elasticache purchase-reserved-cache-nodes-offering \
  --reserved-cache-nodes-offering-id <OFFERING_ID> \
  --cache-node-count 1 \
  --tags Key=Project,Value=FinTechGlobal
```

### 3) Coverage Analysis (5 Points)
**Audit Schedule:** Monthly (1st business day).

| Metric | Target | Remediation Action |
|:--- |:--- |:--- |
| **SP Coverage** | > 70% | Purchase additional Savings Plan layers (stackable). |
| **RI Coverage** | > 80% | Convert On-Demand RDS/Redis to RI if usage stabilized. |
| **RI Utilization** | > 90% | Rightsizing or convert Standard RI to Convertible RI. |

**CLI for RI Coverage:**
```bash
aws ce get-reservation-coverage \
  --time-period Start=$(date -d "-30 days" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY
```

---

## 6.2 Cost Monitoring (25 Points)

**Objective:** Proactive alerting to prevent budget overruns.

### 1) AWS Budgets (10 Points)
**Alerts:** Email (`finops@fintech-global.com`) & SNS (`arn:aws:sns:us-east-1:<ACC>:FinTech-Alerts`).
**Thresholds:** 50% (Info), 80% (Warning), 100% (Critical).

**A. Create Global Budget**
```bash
aws budgets create-budget --account-id <ACC_ID> --budget '{
    "BudgetName": "FinTech-Global-Monthly",
    "BudgetLimit": {"Amount": "5000", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
}' --notifications-with-subscribers '[
    {"Notification": {"NotificationType": "ACTUAL", "Threshold": 80, "ComparisonOperator": "GREATER_THAN"}, "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "finops@fintech-global.com"}]}
]'
```

**B. Service Budgets (ECS, RDS, S3)**
*Repeat creation for:*
-   `FinTech-ECS-Budget`: Filter `Service: Amazon Elastic Container Service`
-   `FinTech-RDS-Budget`: Filter `Service: Amazon Relational Database Service`
-   `FinTech-S3-Budget`: Filter `Service: Amazon Simple Storage Service`

### 2) Cost Anomaly Detection (10 Points)
**Configuration:** Service-level monitoring with immediate alerts.

```bash
# 1. Create Monitor
aws ce create-anomaly-monitor \
  --monitor-name "FinTech-Service-Monitor" \
  --monitor-type DIMENSIONAL \
  --monitor-dimension SERVICE

# 2. Create Subscription
aws ce create-anomaly-subscription \
  --subscription-name "FinTech-Anomaly-Alerts" \
  --threshold 100 \
  --frequency IMMEDIATE \
  --monitor-arn-list <MONITOR_ARN> \
  --subscribers Address=finops@fintech-global.com,Type=EMAIL Address=<SNS_ARN>,Type=SNS
```

### 3) Cost & Usage Report (CUR) + Athena (5 Points)
**Objective:** Granular SQL analysis.

**A. S3 Bucket & Report**
-   **Bucket:** `fintech-cost-reports-<ACCOUNT_ID>`
-   **Prefix:** `cur-data/`
-   **Format:** Parquet, Hourly.

**B. Glue Setup**
```bash
aws glue create-crawler --name cur-crawler --role <GLUE_ROLE> --targets S3Targets=[{Path="s3://fintech-cost-reports/cur-data/"}]
```

**C. Athena Table DDL (Example)**
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS cost_report (
  identity_line_item_id STRING,
  bill_billing_period_start_date TIMESTAMP,
  line_item_usage_start_date TIMESTAMP,
  line_item_product_code STRING,
  line_item_usage_type STRING,
  line_item_unblended_cost DOUBLE
)
STORED AS PARQUET
LOCATION 's3://fintech-cost-reports/cur-data/';
```

**D. Analysis Query (Top Services)**
```sql
SELECT line_item_product_code, SUM(line_item_unblended_cost) as cost
FROM cost_report
WHERE line_item_usage_start_date > ago(30d)
GROUP BY line_item_product_code
ORDER BY cost DESC;
```

---

## 6.3 Optimization Implementation (25 Points)

**Objective:** Architectural efficiency.

### 1) Right Sizing (10 Points)
**Tool:** AWS Compute Optimizer.

**Enablement:**
```bash
aws compute-optimizer update-enrollment-status --status Active
```

**Check Recommendations:**
```bash
# ECS Services
aws compute-optimizer get-ecs-service-recommendations --service-arns <ARN>

# EC2 / EBS (Migrate gp2 -> gp3)
aws ec2 modify-volume --volume-id <VOL_ID> --volume-type gp3
```

### 2) Spot Usage Strategy (10 Points)
**Target:** 60% Spot / 40% On-Demand for Stateless ECS Tasks.

**Implementation (Service Update):**
```bash
aws ecs update-service \
  --cluster fintech-prod-cluster \
  --service fintech-api-svc \
  --capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=6,base=0 capacityProvider=FARGATE,weight=4,base=1 \
  --force-new-deployment
```
*   **Base=1:** Ensures at least 1 task is always FARGATE (On-Demand) for baseline stability.
*   **Weight 6:4:** Splits remaining traffic 60% Spot, 40% OD.

### 3) Storage Tiering (5 Points)
**Strategy:** Aggressive Lifecycle policies for Logs and Archives.

**Lifecycle Policy (`lifecycle.json`):**
```json
{
    "Rules": [
        {
            "ID": "IntelligentTiering-Raw",
            "Prefix": "raw/",
            "Status": "Enabled",
            "Transitions": [ { "Days": 0, "StorageClass": "INTELLIGENT_TIERING" } ]
        },
        {
            "ID": "Archive-Glacier",
            "Prefix": "archive/",
            "Status": "Enabled",
            "Transitions": [ { "Days": 90, "StorageClass": "GLACIER" }, { "Days": 180, "StorageClass": "DEEP_ARCHIVE" } ],
            "NoncurrentVersionExpiration": { "NoncurrentDays": 365 }
        }
    ]
}
```

**Apply Command:**
```bash
aws s3api put-bucket-lifecycle-configuration --bucket <BUCKET_NAME> --lifecycle-configuration file://lifecycle.json
```

---

## 7. Enterprise Validation & Compliance

### Validation Commands
| Component | Command | Success Criteria |
|:--- |:--- |:--- |
| **SP Coverage** | `aws ce get-savings-plans-coverage` | `> 70%` |
| **Spot Ratio** | `aws ecs describe-services` | `capacityProviderStrategy` has `FARGATE_SPOT` |
| **Anomaly Detection** | `aws ce get-anomaly-monitors` | `MonitorCount > 0` |
| **S3 Lifecycle** | `aws s3api get-bucket-lifecycle-configuration` | Returns JSON with Tiering rules |

### Cost Compliance Mapping
-   **SOC2 CC6.1:** Access to Billing Dashboard restricted to FinOps role.
-   **PCI DSS 12.1:** Resource inventory tracked via CUR and Config.

### Monthly FinOps Review
- [ ] Review Cost Anomaly alerts from previous month.
- [ ] Check Savings Plan utilization (should be near 100%).
- [ ] Identify top 3 RDS instances by cost; review Performance Insights for sizing.
- [ ] Confirm all S3 buckets have Lifecycle Policies attached.

### Post-Deployment Checklist
- [ ] Savings Plans active.
- [ ] Budgets active and verified (send test alert).
- [ ] CUR bucket receiving data daily.
- [ ] ECS Services updated to `FARGATE_SPOT` strategy.
- [ ] Storage Lifecycle policies applied.
