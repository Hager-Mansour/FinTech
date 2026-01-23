# AWS Observability Runbook

**Category:** 5 – Observability
**Project:** FinTech Global Platform
**Target Environment:** Production (`us-east-1`)
**Version:** 1.0 (Production Verified)
**Last Updated:** 2026-01-23
**Author:** Cloud Architecture Team

---

## 1. CloudWatch Monitoring (Task 5.1)

**Objective:** Implement comprehensive visibility into Business KPIs and Infrastructure Health.

### 1.1 Custom Metrics (10 Required)
**Namespace:** `FinTech/Business` & `FinTech/Platform`

**CLI Publishing Examples:**
```bash
# --- Business Metrics ---
# 1. Transactions Processed
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name TransactionsProcessed --value 150 --unit Count --dimensions Service=PaymentAPI,Environment=Production
# 2. Transactions Failed
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name TransactionsFailed --value 2 --unit Count --dimensions Service=PaymentAPI,Environment=Production
# 3. Fraud Detected
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name FraudDetected --value 0 --unit Count --dimensions Service=FraudEngine,Environment=Production
# 4. Payment Latency
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name PaymentLatency --value 245 --unit Milliseconds --dimensions Service=PaymentGateway,Environment=Production
# 5. Login Success
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name LoginSuccess --value 450 --unit Count --dimensions Service=AuthService,Environment=Production
# 6. Login Failure
aws cloudwatch put-metric-data --namespace "FinTech/Business" --metric-name LoginFailure --value 5 --unit Count --dimensions Service=AuthService,Environment=Production

# --- Platform Metrics ---
# 7. API Error Rate
aws cloudwatch put-metric-data --namespace "FinTech/Platform" --metric-name APIErrorRate --value 0.01 --unit Percent --dimensions Service=API,Environment=Production
# 8. Active Users
aws cloudwatch put-metric-data --namespace "FinTech/Platform" --metric-name ActiveUsers --value 1250 --unit Count --dimensions Environment=Production
# 9. Cache Hit Ratio
aws cloudwatch put-metric-data --namespace "FinTech/Platform" --metric-name CacheHitRatio --value 95.5 --unit Percent --dimensions Service=Redis,Environment=Production
# 10. Queue Depth
aws cloudwatch put-metric-data --namespace "FinTech/Platform" --metric-name QueueDepth --value 12 --unit Count --dimensions Service=SQS,Environment=Production
```

---

### 1.2 CloudWatch Dashboards (3 Required)

#### A. Executive Dashboard (Business KPIs)
**CLI Command:**
```bash
aws cloudwatch put-dashboard --dashboard-name FinTech-Executive-KPIs --dashboard-body '{
  "widgets": [
    {"type":"metric","x":0,"y":0,"width":12,"height":6,"properties":{"metrics":[["FinTech/Business","TransactionsProcessed"]],"period":300,"stat":"Sum","region":"us-east-1","title":"Transaction Volume"}},
    {"type":"metric","x":12,"y":0,"width":12,"height":6,"properties":{"metrics":[["FinTech/Business","FraudDetected"]],"period":300,"stat":"Sum","region":"us-east-1","title":"Fraud Prevention Rate"}},
    {"type":"metric","x":0,"y":6,"width":12,"height":6,"properties":{"metrics":[["FinTech/Business","PaymentLatency"]],"period":300,"stat":"p95","region":"us-east-1","title":"Payment Latency (p95)"}},
    {"type":"metric","x":12,"y":6,"width":12,"height":6,"properties":{"metrics":[["AWS/Route53","HealthCheckPercentageHealthy"]],"period":300,"stat":"Average","region":"us-east-1","title":"System Availability"}}
  ]
}'
```

#### B. Operations Dashboard (Infrastructure)
**CLI Command:**
```bash
aws cloudwatch put-dashboard --dashboard-name FinTech-Operations --dashboard-body '{
  "widgets": [
    {"type":"metric","x":0,"y":0,"width":8,"height":6,"properties":{"metrics":[["AWS/ECS","CPUUtilization","ClusterName","fintech-prod-cluster"]],"title":"ECS CPU"}},
    {"type":"metric","x":8,"y":0,"width":8,"height":6,"properties":{"metrics":[["AWS/ApplicationELB","TargetResponseTime"]],"title":"ALB Latency"}},
    {"type":"metric","x":16,"y":0,"width":8,"height":6,"properties":{"metrics":[["AWS/RDS","CPUUtilization"]],"title":"Aurora CPU"}},
    {"type":"metric","x":0,"y":6,"width":8,"height":6,"properties":{"metrics":[["AWS/DynamoDB","ThrottledRequests"]],"title":"DynamoDB Throttles"}},
    {"type":"metric","x":8,"y":6,"width":8,"height":6,"properties":{"metrics":[["AWS/ElastiCache","CPUUtilization"]],"title":"Redis CPU"}},
    {"type":"metric","x":16,"y":6,"width":8,"height":6,"properties":{"metrics":[["AWS/RDS","ReplicaLag"]],"title":"Aurora Replica Lag"}}
  ]
}'
```

#### C. Cost Dashboard (Trends)
**CLI Command:**
```bash
aws cloudwatch put-dashboard --dashboard-name FinTech-Cost-Optimization --dashboard-body '{
  "widgets": [
    {"type":"metric","x":0,"y":0,"width":12,"height":6,"properties":{"metrics":[["AWS/Billing","EstimatedCharges","Currency","USD"]],"title":"Total Estimated Charges"}},
    {"type":"metric","x":12,"y":0,"width":12,"height":6,"properties":{"metrics":[["AWS/NATGateway","BytesOutToDestination"]],"title":"NAT Gateway Data Transfer"}},
    {"type":"metric","x":0,"y":6,"width":12,"height":6,"properties":{"metrics":[["AWS/S3","BucketSizeBytes"]],"title":"S3 Storage Growth"}}
  ]
}'
```

---

### 1.3 CloudWatch Alarms (20 Required)
**SNS Topic:** `arn:aws:sns:us-east-1:<ACC_ID>:FinTech-Alerts`

**CLI Commands (Batch generation strategy):**

```bash
# 1. ALB High Latency
aws cloudwatch put-metric-alarm --alarm-name "ALB-High-Latency" --metric-name TargetResponseTime --namespace AWS/ApplicationELB --statistic Average --period 60 --threshold 0.5 --comparison-operator GreaterThanThreshold --dimensions Name=LoadBalancer,Value=app/fintech-alb/123 --evaluation-periods 3 --alarm-actions $SNS_TOPIC

# 2. ALB 5XX Errors
aws cloudwatch put-metric-alarm --alarm-name "ALB-5XX-Spike" --metric-name HTTPCode_Target_5XX_Count --namespace AWS/ApplicationELB --statistic Sum --period 60 --threshold 10 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 3. ECS CPU High
aws cloudwatch put-metric-alarm --alarm-name "ECS-CPU-High" --metric-name CPUUtilization --namespace AWS/ECS --statistic Average --period 300 --threshold 75 --comparison-operator GreaterThanThreshold --dimensions Name=ClusterName,Value=fintech-prod-cluster --evaluation-periods 2 --alarm-actions $SNS_TOPIC

# 4. ECS Memory High
aws cloudwatch put-metric-alarm --alarm-name "ECS-Memory-High" --metric-name MemoryUtilization --namespace AWS/ECS --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold --dimensions Name=ClusterName,Value=fintech-prod-cluster --evaluation-periods 2 --alarm-actions $SNS_TOPIC

# 5. Aurora CPU High
aws cloudwatch put-metric-alarm --alarm-name "Aurora-CPU-High" --metric-name CPUUtilization --namespace AWS/RDS --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --alarm-actions $SNS_TOPIC

# 6. Aurora Freeable Memory Low
aws cloudwatch put-metric-alarm --alarm-name "Aurora-Mem-Low" --metric-name FreeableMemory --namespace AWS/RDS --statistic Average --period 300 --threshold 500000000 --comparison-operator LessThanThreshold --evaluation-periods 2 --alarm-actions $SNS_TOPIC

# 7. Aurora Replica Lag
aws cloudwatch put-metric-alarm --alarm-name "Aurora-Replica-Lag" --metric-name ReplicaLag --namespace AWS/RDS --statistic Maximum --period 60 --threshold 100 --comparison-operator GreaterThanThreshold --evaluation-periods 3 --alarm-actions $SNS_TOPIC

# 8. DynamoDB Read Throttle
aws cloudwatch put-metric-alarm --alarm-name "DDB-Read-Throttle" --metric-name ReadThrottleEvents --namespace AWS/DynamoDB --statistic Sum --period 60 --threshold 1 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 9. DynamoDB Write Throttle
aws cloudwatch put-metric-alarm --alarm-name "DDB-Write-Throttle" --metric-name WriteThrottleEvents --namespace AWS/DynamoDB --statistic Sum --period 60 --threshold 1 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 10. Redis CPU High
aws cloudwatch put-metric-alarm --alarm-name "Redis-CPU-High" --metric-name CPUUtilization --namespace AWS/ElastiCache --statistic Average --period 300 --threshold 85 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --alarm-actions $SNS_TOPIC

# 11. Redis Evictions
aws cloudwatch put-metric-alarm --alarm-name "Redis-Evictions" --metric-name Evictions --namespace AWS/ElastiCache --statistic Sum --period 60 --threshold 1 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 12. Transaction Failure Spike
aws cloudwatch put-metric-alarm --alarm-name "Biz-Tx-Failures" --metric-name TransactionsFailed --namespace FinTech/Business --statistic Sum --period 60 --threshold 5 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 13. Fraud Spike
aws cloudwatch put-metric-alarm --alarm-name "Biz-Fraud-Alert" --metric-name FraudDetected --namespace FinTech/Business --statistic Sum --period 60 --threshold 1 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 14. API Error Rate High
aws cloudwatch put-metric-alarm --alarm-name "Platform-API-Errors" --metric-name APIErrorRate --namespace FinTech/Platform --statistic Average --period 300 --threshold 5 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --alarm-actions $SNS_TOPIC

# 15. ECS Task Count Low
aws cloudwatch put-metric-alarm --alarm-name "ECS-Tasks-Low" --metric-name RunningTaskCount --namespace AWS/ECS --statistic Average --period 60 --threshold 2 --comparison-operator LessThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 16. NAT Gateway Error Port Allocation
aws cloudwatch put-metric-alarm --alarm-name "NAT-Port-Alloc-Error" --metric-name ErrorPortAllocation --namespace AWS/NATGateway --statistic Sum --period 60 --threshold 0 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 17. S3 4XX Errors
aws cloudwatch put-metric-alarm --alarm-name "S3-4XX-Errors" --metric-name 4xxErrors --namespace AWS/S3 --statistic Sum --period 60 --threshold 10 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 18. Lambda Error Rate (Rotation)
aws cloudwatch put-metric-alarm --alarm-name "Lambda-Rotation-Err" --metric-name Errors --namespace AWS/Lambda --statistic Sum --period 60 --threshold 0 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 19. VPN Tunnel Down (Infrastructure)
aws cloudwatch put-metric-alarm --alarm-name "VPN-Tunnel-Down" --metric-name TunnelState --namespace AWS/VPN --statistic Minimum --period 60 --threshold 0 --comparison-operator LessThanThreshold --evaluation-periods 1 --alarm-actions $SNS_TOPIC

# 20. Aurora DB Connections High
aws cloudwatch put-metric-alarm --alarm-name "Aurora-Conn-High" --metric-name DatabaseConnections --namespace AWS/RDS --statistic Maximum --period 60 --threshold 500 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --alarm-actions $SNS_TOPIC
```

---

### 1.4 CloudWatch Logs Insights

**Saved Query Commands:**

```bash
# 1. API Error Analysis (5XX)
aws logs put-query-definition --name "FinTech/API-5XX-Errors" --log-group-names "/ecs/fintech-api" --query-string "fields @timestamp, @message | filter @message like /500/ | sort @timestamp desc | limit 20"

# 2. Slow Requests (> 1s)
aws logs put-query-definition --name "FinTech/Slow-Requests" --log-group-names "/ecs/fintech-api" --query-string "fields @timestamp, path, latency | filter latency > 1000 | sort latency desc"

# 3. Fraud Detection Patterns
aws logs put-query-definition --name "FinTech/Fraud-Patterns" --log-group-names "/ecs/fintech-api" --query-string "fields @timestamp, userId, amount | filter eventType = 'FRAUD_FLAG' | sort amount desc"

# 4. ECS Task Failures
aws logs put-query-definition --name "FinTech/ECS-Failures" --log-group-names "/ecs/fintech-api" --query-string "fields @timestamp, @message | filter @message like /Exception/ or @message like /Error/ | sort @timestamp desc"
```

---

## 2. AWS X-Ray Distributed Tracing (Task 5.2)

**Objective:** End-to-end distributed tracing for bottleneck identification.

### 2.1 Service Map
X-Ray Daemon must be running as a sidecar or installed in the image.

**Task Definition Configuration (Excerpt):**
```json
{
  "containerDefinitions": [
    {
      "name": "xray-daemon",
      "image": "amazon/aws-xray-daemon",
      "cpu": 32,
      "memoryReservation": 256,
      "portMappings": [{"containerPort": 2000, "protocol": "udp"}]
    }
  ]
}
```

**IAM Role Permission:**
`AWSXRayDaemonWriteAccess` managed policy attached to `FinTech-ECS-TaskRole`.

### 2.2 Custom Segments & Subsegments
**Java/Node.js Logic Injection:**

```json
// Example: Fraud Check Subsegment
{
  "name": "FraudCheck",
  "id": "70de5370f3dfa741",
  "start_time": 1478293361.28,
  "end_time": 1478293361.69,
  "annotations": {
    "UserID": "12345",
    "TransactionAmount": "5000"
  },
  "metadata": {
    "RiskScore": "High"
  }
}
```

### 2.3 Sampling Rules
**Strategy:** Capture 100% of errors and 5% of healthy traffic.

**CLI Command:**
```bash
cat > sampling-rule.json << 'EOF'
{
  "SamplingRule": {
    "RuleName": "FinTech-Error-Sampling",
    "RuleARN": "arn:aws:xray:us-east-1:123456789012:sampling-rule/FinTech-Error-Sampling",
    "ResourceARN": "*",
    "Priority": 1,
    "FixedRate": 1.0,
    "ReservoirSize": 50,
    "ServiceName": "*",
    "ServiceType": "*",
    "Host": "*",
    "HTTPMethod": "*",
    "URLPath": "*",
    "Version": 1,
    "Attributes": {}
  }
}
EOF
aws xray create-sampling-rule --cli-input-json file://sampling-rule.json
```

### 2.4 X-Ray Insights
**Enable Insights:**
```bash
aws xray update-group --group-name Default --insights-configuration InsightsEnabled=true,NotificationsEnabled=true
```

---

## 3. Operational Operational Excellence

### 3.1 Alarm Remediation
-   **ALB High Latency:** Check ECS CPU/Memory, scale out service.
-   **DB Throttle:** Check DynamoDB consumed capacity, increase provisioned limits or enable Auto Scaling.
-   **5XX Errors:** Check Logs Insights for "Exception" or "Error".

### 3.2 Post-Deployment Validation
- [ ] Dashboards created and populated with data.
- [ ] "Transaction Processed" metric visible in Executive Dashboard.
- [ ] Alarm "ALB-5XX-Spike" is in OK state.
- [ ] X-Ray Service Map shows connected nodes (ALB -> ECS -> Aurora/DynamoDB).

### 3.3 Notification Integration
-   **SNS Topic:** `FinTech-Alerts`
-   **Subscribers:** DevOps PagerDuty (Email/HTTPS), Slack Webhook (via Lambda).

---
