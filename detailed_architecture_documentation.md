# Comprehensive FinTech Global Platform Architecture Documentation

## 1. Foundation & Organization

### 1.1 Category Overview
The Foundation & Organization category establishes the governance, security, and structural framework for the entire FinTech Global Platform. It utilizes a multi-account strategy via AWS Organizations to ensure strict isolation between environments (Dev, Staging, Prod) and functional areas (Security, Infrastructure), implementing a "defense-in-depth" posture from the account level up.

### 1.2 Components / Tasks Table

| Component Name | Service Type | Purpose | AWS Service Used | Criticality Level |
| :--- | :--- | :--- | :--- | :--- |
| **Organization Structure** | Managed | Hierarchical account grouping & isolation | AWS Organizations | High |
| **Security OUs & Accounts** | Managed | Centralized security audit & logging | AWS Organizations / IAM | High |
| **Service Control Policies** | Managed | Guardrails to deny prohibited actions | AWS Organizations (SCP) | High |
| **Tagging Strategy** | Managed | Cost allocation & resource lifecycle | AWS Resource Groups | Medium |
| **Well-Architected Review** | Managed | Architectural audit & best practices | AWS Well-Architected Tool | Medium |

### 1.3 Detailed Component Documentation

#### A. Organization Structure & OUs
*   **Definition:** A hierarchical tree of Organizational Units (OUs) including Security, Infrastructure, Workloads, and Sandbox.
*   **Importance:** Prevents resource conflict and security breaches by physically separating production workloads from lower environments.
*   **Core Functions:** Grouping accounts, applying policy inheritance, centralized billing.
*   **Architecture Interaction:** Root of the dependency tree; all other resources live within these accounts.
*   **Production Outcome:** Clean separation of duties; improved billing visibility.
*   **Failure Impact:** Configuration drift or security gaps if structure is bypassed (Unlikely with SCPs).
*   **Scaling Behavior:** Scales horizontally by adding new accounts/OUs as teams grow.
*   **Security Considerations:** Root management account must be strictly locked down (MFA, hardware keys).

#### B. Service Control Policies (SCPs)
*   **Definition:** JSON-based policies applied to OUs to limit maximum available permissions for member accounts.
*   **Importance:** hard-enforces compliance requirements (e.g., "Must stay in us-east-1") that even root users in member accounts cannot bypass.
*   **Core Functions:** Deny Root User access, Region Restriction, auditing enforcement.
*   **Architecture Interaction:** Overrides all local IAM policies; acts as the ultimate firewall for permissions.
*   **Production Outcome:** Mathematical guarantee of compliance rules.
*   **Failure Impact:** If misconfigured (too strict), can block legitimate operations; if too loose, allows compliance violations.
*   **Scaling Behavior:** Policies apply instantly to all new accounts in an OU.
*   **Security Considerations:** Changes to SCPs should require multi-person approval.

#### C. Tagging Strategy
*   **Definition:** A standardized metadata schema (Environment, Project, CostCenter, DataClassification) enforced via Config Rules.
*   **Importance:** Essential for accurate cost attribution and automated automation (e.g., backups based on tags).
*   **Core Functions:** Resource identification, cost tracking, automation triggering.
*   **Architecture Interaction:** Interacts with Cost Explorer, AWS Backup, and Automation scripts.
*   **Production Outcome:** 100% cost visibility; automated compliance reporting.
*   **Failure Impact:** Loss of cost granularity; failure of tag-based automation.
*   **Scaling Behavior:** N/A (Methodology).
*   **Security Considerations:** Sensitive tags (e.g., PII indicators) should not store actual data.

### 1.4 Architecture Flow Summary
1.  Root Admin logs into Management Account.
2.  Creates new Account via AWS Organizations.
3.  Moves Account to "Production OU".
4.  SCP "Deny-All-Non-US-East-1" is automatically applied.
5.  Billing for the account is automatically aggregated to the Management payer.

### 1.5 Operational Impact
*   **Performance:** No runtime impact.
*   **Availability:** High (AWS Control Plane).
*   **Security:** Foundational; strictly limits blast radius.
*   **Cost:** No direct cost (Free service), but enables cost optimization via billing data accumulation.

### 1.6 Best Practices
*   **Least Privilege:** SCPs should deny, not allow. Leave allows to IAM.
*   **Break-Glass Access:** Maintain emergency access to the management account.
*   **Automated Provisioning:** Use Control Tower or Terraform for account vending.
*   **Immutable Logs:** Enable CloudTrail in all accounts, consolidated to the Security-Logging account.

### 1.7 Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Root Account Compromise** | Total system takeover | MFA + Hardware Token on Root; use only for account creation. |
| **SCP Misconfiguration** | Production outage (Lockout) | Test SCPs in Sandbox/Dev OUs before promoting to Production. |
| **Billing Shock** | Unexpected large invoice | Unified Billing with Budgets applied at the Root level across all OUs. |

---

## 2. Networking

### 2.1 Category Overview
The Networking module defines the virtual network topology for the platform. It revolves around a Production VPC in `us-east-1` designed for high availability across two Availability Zones (AZs), utilizing a tiered subnet strategy to isolate public-facing ingress from secure internal app and data layers.

### 2.2 Components / Tasks Table

| Component Name | Service Type | Purpose | AWS Service Used | Criticality Level |
| :--- | :--- | :--- | :--- | :--- |
| **Production VPC** | Managed | Isolated network environment | Amazon VPC | High |
| **Subnet Tiers** | Stateless | Logic/Data isolation | VPC Subnets | High |
| **NAT Gateways** | Managed | Outbound internet for private instances | NAT Gateway | High |
| **VPC Endpoints** | Managed | Private AWS service access | PrivateLink | Medium |
| **Security Groups** | Stateful | Instance-level firewalls | VPC Security Groups | High |

### 2.3 Detailed Component Documentation

#### A. VPC & Subnet Tiers (Public/App/Data)
*   **Definition:** A CIDR block (10.0.0.0/16) segmented into Public (ALB), Private App (ECS), and Private DB (Aurora/Redis) subnets across AZ-A and AZ-B.
*   **Importance:** Fundamental layer for connectivity and security isolation.
*   **Core Functions:** IP address management, network boundary definition, routing.
*   **Architecture Interaction:** Hosts all EC2/Fargate/RDS resources.
*   **Production Outcome:** Organized network addressing; simplified routing logic.
*   **Failure Impact:** Subnet failure (rare) equates to AZ failure.
*   **Scaling Behavior:** CIDR based; ample IP space (/16) allows for massive horizontal scaling.
*   **Security Considerations:** NACLs act as stateless backup to Security Groups.

#### B. NAT Gateways (Multi-AZ)
*   **Definition:** Managed network address translation services deployed in Public subnets.
*   **Importance:** Allows private resources (ECS Tasks) to pull updates/patches from the internet without exposing them to inbound connections.
*   **Core Functions:** Outbound-only internet access.
*   **Architecture Interaction:** Route target for 0.0.0.0/0 in Private Route Tables.
*   **Production Outcome:** Secure patch management; connectivity to external 3rd party APIs (Stripe, SendGrid).
*   **Failure Impact:** Loss of outbound connectivity for app layer (cannot reach 3rd party APIs).
*   **Scaling Behavior:** Automatically handled by AWS up to 45Gbps.
*   **Security Considerations:** Use Network Firewall/Gateway Load Balancer if deep packet inspection is needed.

#### C. VPC Endpoints (Interface/Gateway)
*   **Definition:** Private links to AWS services (S3, ECR, Secrets Manager) bypassing the public internet.
*   **Importance:** Enhances security by keeping traffic entirely within the AWS network; reduces NAT Gateway data processing costs.
*   **Core Functions:** Secure routing to AWS PaaS services.
*   **Architecture Interaction:** DNS resolution within VPC resolves service endpoints to private IPs.
*   **Production Outcome:** Reduced latency; improved security posture; lower data transfer costs.
*   **Failure Impact:** App fails to pull secrets/images if endpoint is down (rare).
*   **Scaling Behavior:** Horizontal scaling managed by AWS.
*   **Security Considerations:** Endpoint Policies to restrict which buckets/resources can be accessed.

### 2.4 Architecture Flow Summary
1.  **Ingress:** User request -> IGW -> ALB (Public Subnet).
2.  **Processing:** ALB -> ECS Task (Private App Subnet).
3.  **Data Access:** ECS Task -> Aurora/Redis (Private DB Subnet).
4.  **External Call:** ECS Task -> NAT GW (Public Subnet) -> IGW -> Internet (Stripe API).
5.  **Internal SVC:** ECS Task -> VPC Endpoint -> Secrets Manager (Internal AWS Network).

### 2.5 Operational Impact
*   **Performance:** Microsecond latency within VPC; low latency via Endpoints.
*   **Availability:** High (Multi-AZ redundancy for all components).
*   **Security:** Strong isolation; private subnets are unreachable from internet.
*   **Cost:** NAT Gateways and VPC Endpoints have hourly + data processing charges (Cost driver).

### 2.6 Best Practices
*   **No Public DBs:** Never place databases in public subnets.
*   **Flow Logs:** Enable VPC Flow Logs for traffic auditing.
*   **NACLs:** Use Network ACLs for coarse-grained subnet blocking (denylists).
*   **DNS:** Enable DNS Hostnames and Resolution for Endpoint functionality.

### 2.7 Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **AZ Failure** | 50% capacity loss | Automatic routing to healthy AZ via ALB and Multi-AZ DB failover. |
| **NAT GW Cost** | High data charges | Route heavy AWS traffic (S3/ECR) through VPC Endpoints to bypass NAT. |
| **IP Exhaustion** | Unable to launch new pods | Use adequately sized subnets (e.g., /24 or larger) for App layer. |

---

## 3. Compute & Containers

### 3.1 Category Overview
The compute layer powers the business logic using Amazon ECS. It leverages a serverless-first approach with AWS Fargate for API tasks, maintaining flexibility to use EC2 for specific needs. The cluster is fronted by an Application Load Balancer (ALB) and governed by strict Auto Scaling policies to handle the 1,000 TPS requirement.

### 3.2 Components / Tasks Table

| Component Name | Service Type | Purpose | AWS Service Used | Criticality Level |
| :--- | :--- | :--- | :--- | :--- |
| **ECS Cluster** | Managed | Container orchestration boundary | Amazon ECS | High |
| **Fargate Tasks** | Serverless | Run application containers | AWS Fargate | High |
| **ECR Repository** | Managed | Store Docker images | Amazon ECR | High |
| **Application Load Balancer** | Managed | Layer 7 Traffic distribution | Elastic Load Balancing | High |
| **Auto Scaling Policies** | Managed | Dynamic capacity adjustment | App Auto Scaling | High |
| **Task IAM Roles** | Identity | Least-privilege permissions | IAM | High |

### 3.3 Detailed Component Documentation

#### A. ECS Cluster & Fargate Tasks
*   **Definition:** Logical grouping of tasks (containers) running the Node.js/Python banking API.
*   **Importance:** Hosts the core revenue-generating application.
*   **Core Functions:** Process API requests, execute business logic, interface with DB.
*   **Architecture Interaction:** Polled by ALB; connects to Aurora/Redis/S3.
*   **Production Outcome:** Zero server management; distinct isolation per task.
*   **Failure Impact:** App downtime if all tasks fail.
*   **Scaling Behavior:** Scales horizontally (add more tasks) based on CPU/Memory/Request Count.
*   **Security Considerations:** Immutable infrastructure; read-only root filesystems recommended.

#### B. Application Load Balancer (ALB)
*   **Definition:** Layer 7 load balancer terminating TLS and routing traffic to Target Groups.
*   **Importance:** Single entry point for all client traffic; handles SSL offloading.
*   **Core Functions:** Health checks, path-based routing, TLS termination.
*   **Architecture Interaction:** Sits in Public Subnets; forwards to Private Subnets.
*   **Production Outcome:** High availability; seamless deployments (blue/green capabilities).
*   **Failure Impact:** Total service outage for external users.
*   **Scaling Behavior:** Scales automatically via AWS (LBCUs).
*   **Security Considerations:** Security Group allowing 80/443 from 0.0.0.0/0 (or CloudFront only); WAF integration.

#### C. IAM Roles (Execution vs. Task)
*   **Definition:**
    *   *Execution Role:* Permissions for the ECS agent (pull images, send logs).
    *   *Task Role:* Permissions for the *app code* (read S3, query DynamoDB).
*   **Importance:** Enforces granular least-privilege security.
*   **Core Functions:** Authentication and Authorization for AWS API calls.
*   **Architecture Interaction:** Assumed by Fargate tasks at runtime.
*   **Production Outcome:** No hardcoded credentials in containers.
*   **Failure Impact:** Application crashes (`AccessDenied`) if permissions are missing.
*   **Scaling Behavior:** N/A.
*   **Security Considerations:** Task Role should never have `*:*`.

### 3.4 Architecture Flow Summary
1.  **Deployment:** GitHub Action pushes image to ECR -> Triggers ECS Update.
2.  **Startup:** ECS Scheduler provisons Fargate Task -> Pulls Image (ECR) -> Pulls Secrets (Secrets Manager).
3.  **Runtime:** ALB Health Check passes -> Traffic starts flowing.
4.  **Scaling:** CloudWatch Alarm (CPU > 70%) -> Auto Scaling Policy -> Adjust Desired Count -> ECS adds tasks.

### 3.5 Operational Impact
*   **Performance:** Fargate startup time (~30-60s) affects scaling speed.
*   **Availability:** High (Spread across multiple AZs).
*   **Security:** Container isolation; temporary credentials.
*   **Cost:** Linear cost growth with traffic; optimization via Spot/Savings Plans.

### 3.6 Best Practices
*   **Health Checks:** Implement deep health checks (DB connectivity) but with generous timeouts.
*   **Graceful Shutdown:** Handle SIGTERM signals to finish in-flight requests before task termination.
*   **Logging:** Ship stdout/stderr to CloudWatch Logs (or FireLens).
*   **Tagging:** Propagate tags from Task Definition to Task for cost allocation.

### 3.7 Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Bad Deployment** | Application Crash Loop | Circuit breakers; Rollback alarms in CodeDeploy/ECS. |
| **Slow Scaling** | Latency spike during bursts | Use Target Tracking with low threshold (50-60%) or Step Scaling for aggressive scale-out. |
| **Image Vulnerability** | Security breach | Enable ECR Image Scanning on Push; block deployment of critical CVEs. |

---

## 4. Data Layer & Secrets Management

### 4.1 Category Overview
The state layer enforces data consistency and durability. It uses Aurora PostgreSQL for relation transactional data (Ledger), DynamoDB for high-velocity key-value data (Sessions), ElastiCache Redis for read-acceleration, and S3 for document storage. All credentials are protected by Secrets Manager and KMS.

### 4.2 Components / Tasks Table

| Component Name | Service Type | Purpose | AWS Service Used | Criticality Level |
| :--- | :--- | :--- | :--- | :--- |
| **Relational DB** | Stateful | ACID Transactions (Ledger/User Profile) | Amazon Aurora PostgreSQL | Critical |
| **NoSQL Store** | Serverless | High-throughput Session/State | Amazon DynamoDB | Critical |
| **Caching Layer** | Stateful | Sub-ms read acceleration | Amazon ElastiCache (Redis) | High |
| **Data Lake** | Stateful | Object storage, logs, analytics | Amazon S3 | Medium |
| **Secrets Mgmt** | Managed | Credential rotation & storage | AWS Secrets Manager | Critical |

### 4.3 Detailed Component Documentation

#### A. Aurora PostgreSQL Cluster (Multi-AZ)
*   **Definition:** A managed relational database cluster with 1 Writer and 1+ Readers.
*   **Importance:** The system of record for all financial transactions.
*   **Core Functions:** ACID transactions, referential integrity, complex queries.
*   **Architecture Interaction:** Accessed by ECS tasks via connection pooling.
*   **Production Outcome:** 6-way storage replication across 3 AZs; auto-failover (<30s).
*   **Failure Impact:** Read-only mode if writer fails (until failover completes).
*   **Scaling Behavior:** Auto-scaling Read Replicas; storage scales automatically.
*   **Security Considerations:** Encrypted at rest (KMS); enforce SSL connections.

#### B. DynamoDB Tables
*   **Definition:** Key-Value store for transient or simplified data (User Sessions, Shopping Cart).
*   **Importance:** Offloads high-churn IOPS from the main relational DB.
*   **Core Functions:** Fast lookups by Partition Key; expiration via TTL.
*   **Architecture Interaction:** Direct HTTP access via IAM roles (no drivers needed).
*   **Production Outcome:** Single-digit millisecond latency at any scale.
*   **Failure Impact:** App requires re-login if session store fails (System is highly reliable).
*   **Scaling Behavior:** On-Demand or Provisioned with Auto Scaling.
*   **Security Considerations:** Fine-grained access control (LeadingKeys); KMS encryption.

#### C. ElastiCache Redis
*   **Definition:** In-memory data store used for caching frequent queries and API responses.
*   **Importance:** Critical for meeting the <200ms latency requirement.
*   **Core Functions:** Key-Value caching, Sorted Sets (Leaderboards).
*   **Architecture Interaction:** "Cache-Aside" pattern implemented in App Logic.
*   **Production Outcome:** Reduces load on Aurora; speeds up read operations.
*   **Failure Impact:** Increased latency (Cache Stampede) on DB, potential timeouts.
*   **Scaling Behavior:** Cluster mode enabled for sharding; add nodes for read scaling.
*   **Security Considerations:** Run in Private Subnet; Auth Token required (Transit Encryption).

#### D. S3 Data Lake
*   **Definition:** Central repository for raw and processed data (Logs, PDFs, CSVs).
*   **Importance:** Compliance retention and source for analytics/ML.
*   **Core Functions:** Immutable storage, lifecycle management (Transition to Glacier).
*   **Architecture Interaction:** Event notifications can trigger Lambda for processing.
*   **Production Outcome:** Cheap, infinite storage for 7-year retention.
*   **Failure Impact:** Loss of historical usage; Analytics downtime.
*   **Scaling Behavior:** Infinite.
*   **Security Considerations:** Block Public Access; Bucket Policy; Server-Side Encryption.

### 4.4 Architecture Flow Summary
1.  **Write:** App -> Aurora Writer (Insert Transaction).
2.  **Read:** App -> Redis (Check Cache).
    *   *Hit:* Return data.
    *   *Miss:* App -> Aurora Reader -> Update Redis -> Return data.
3.  **Session:** App -> DynamoDB (Get/Put Session Token).
4.  **Audit:** App -> S3 (Async upload of transaction receipt).

### 4.5 Operational Impact
*   **Performance:** heavily dependent on Cache Hit Ratio and DB Schema indexing.
*   **Availability:** Aurora Multi-AZ is resilient; Redis Multi-AZ handles node failure.
*   **Security:** Data is the primary target; Encryption at Rest/Transit is mandatory.
*   **Cost:** Database instance hours and IOPS are major cost drivers.

### 4.6 Best Practices
*   **Connection Pooling:** Use RDS Proxy or client-side pooling to prevent connection exhaustion.
*   **TTL:** Use Time-To-Live on DynamoDB and Redis to auto-expire stale data.
*   **Secrets Rotation:** Automate password rotation every 30-90 days via Secrets Manager.
*   **Backup:** Enable Point-In-Time Recovery (PITR) for Aurora and DynamoDB.

### 4.7 Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Data Loss** | Catastrophic Business Failure | Cross-Region Backup Copies; Deletion Protection enabled. |
| **Cache Stampede** | DB Overload & Crash | Implement Jitter/Backoff; Use Locking mechanisms; Pre-warm cache. |
| **SQL Injection** | Data Exfiltration | Use Parameterized Queries/ORMs; WAF SQLi Constraints. |

---

## 5. Observability

### 5.1 Category Overview
Observability moves beyond simple monitoring ("Is it up?") to understanding system behavior ("Why is it slow?"). This stack utilizes AWS native tools to provide tracing, logging, and metrics, ensuring that the 99.9% availability SLA is measurable and maintainable.

### 5.2 Components / Tasks Table

| Component Name | Service Type | Purpose | AWS Service Used | Criticality Level |
| :--- | :--- | :--- | :--- | :--- |
| **Metrics & Monitoring** | Managed | Numeric data tracking (CPU, Latency) | Amazon CloudWatch Metrics | High |
| **Dashboards** | Managed | Visualization of KPIs | CloudWatch Dashboards | Medium |
| **Alarming** | Managed | Incident triggering | CloudWatch Alarms / SNS | High |
| **Distributed Tracing** | Managed | Request lifecycle visualization | AWS X-Ray | Medium |
| **Log Aggregation** | Managed | Text-based status records | CloudWatch Logs | High |

### 5.3 Detailed Component Documentation

#### A. CloudWatch Metrics & Dashboards
*   **Definition:** Time-series data collected from all AWS services and custom application code.
*   **Importance:** Provides the "pulse" of the application.
*   **Core Functions:** Aggregating data points; visualizing trends (Executive, Ops, Cost views).
*   **Architecture Interaction:** Ingests data from ECS, RDS, ALB, etc.
*   **Production Outcome:** Instant visibility into system health.
*   **Failure Impact:** Blindness to ongoing issues; active incidents might go unnoticed.
*   **Scaling Behavior:** Handles massive ingress of metric data.
*   **Security Considerations:** Restrict dashboard access to authorized personnel only.

#### B. CloudWatch Alarms & SNS
*   **Definition:** Logic rules acting on metrics to trigger notifications or automated actions.
*   **Importance:** Enables proactive response to failures before users report them.
*   **Core Functions:** Threshold checking; sending alerts to Email/SMS/PagerDuty.
*   **Architecture Interaction:** Triggers Auto Scaling; Notifies Ops team.
*   **Production Outcome:** Reduced MTTR (Mean Time To Recovery).
*   **Failure Impact:** Silent failures (if alarms are broken).
*   **Scaling Behavior:** Evaluation of alarms is managed by AWS.
*   **Security Considerations:** Protect SNS topics from unauthorized publishers.

#### C. AWS X-Ray
*   **Definition:** Distributed tracing system that follows a user request as it travels through ALB, ECS, and Database.
*   **Importance:** Essential for debugging latency in microservices architectures.
*   **Core Functions:** Service Mapping, Identify bottlenecks, Error categorization.
*   **Architecture Interaction:** Integrated via SDK in Application Code and Sidecar agent.
*   **Production Outcome:** Ability to pinpoint "slow database query" vs "slow application code".
*   **Failure Impact:** Difficulty diagnosing complex performance issues.
*   **Scaling Behavior:** Sampling based (start with 5-10% sampling to manage cost).
*   **Security Considerations:** Do not trace PII (Personally Identifiable Information).

#### D. CloudWatch Logs
*   **Definition:** Centralized storage for stdout/stderr from containers and system logs.
*   **Importance:** The "Black Box" flight recorder for the application.
*   **Core Functions:** Log ingestion, storage, and querying (Logs Insights).
*   **Architecture Interaction:** Captures output from ECS Task Execution Role.
*   **Production Outcome:** searchable history of all application events.
*   **Failure Impact:** Loss of debug context for past errors.
*   **Scaling Behavior:** Infinite storage; use lifecycle policies to archive to S3.
*   **Security Considerations:** Encrypt logs with KMS; Mask sensitive data before logging.

### 5.4 Architecture Flow Summary
1.  **Generation:** App generates Log Line & Metric -> X-Ray SDK starts segment.
2.  **Collection:** CloudWatch Agent/Daemon pushes data to AWS APIs.
3.  **Analysis:** CloudWatch evaluates Metric against Alarm Threshold.
4.  **Reaction:** Alarm State Change -> Trigger SNS -> Notify Admin / Trigger Auto Scaling.

### 5.5 Operational Impact
*   **Performance:** Tracing adds slight overhead (negligible with sampling).
*   **Availability:** Critical for maintaining availability.
*   **Security:** Audit logs provide forensic capabilities.
*   **Cost:** Logs and Custom Metrics can get expensive; aggressive retention settings are needed.

### 5.6 Best Practices
*   **Structured Logging:** Log in JSON format to enable easy parsing with Logs Insights.
*   **Golden Signals:** Monitor Latency, Traffic, Errors, and Saturation for every service.
*   **Unified Agent:** Use CloudWatch Agent for system-level metrics (RAM, Disk Usage).
*   **Sampling:** Use X-Ray sampling rules to trace only a percentage of requests in Prod.

### 5.7 Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Log Noise** | Missing real errors; High cost | Set log level to INFO/WARN in Prod; DEBUG only for short periods. |
| **Alarm Fatigue** | Operators ignore alerts | Tune thresholds; use "Standard Deviation" (Anomaly Detection) alarms. |
| **Missing Data** | Blind spots | Create "Heartbeat" metrics to ensure monitoring system itself is up. |

---

## 6. Cost Optimization

### 6.1 Category Overview
Cost optimization is not a one-time event but a continuous lifecycle. This category employs both architectural choices (Spot, Auto Scaling) and financial instruments (Savings Plans) to achieve the target 40% reduction compared to on-demand pricing.

### 6.2 Components / Tasks Table

| Component Name | Service Type | Purpose | AWS Service Used | Criticality Level |
| :--- | :--- | :--- | :--- | :--- |
| **Savings Plans** | Financial | Discount for committed compute usage | AWS Billing | High |
| **Fargate Spot** | Compute | Deeply discounted spare capacity | AWS Fargate | Medium |
| **Auto Scaling** | Operational | Match supply to demand | Application Auto Scaling | High |
| **Budgets** | Governance | Spending limits and alerts | AWS Budgets | High |
| **Intelligent Tiering** | Storage | Auto-move cold data to cheap storage | Amazon S3 | Medium |

### 6.3 Detailed Component Documentation

#### A. Compute Savings Plans & Reserved Instances
*   **Definition:** 1- or 3-year commitment to a specific amount of compute usage (measured in $/hour).
*   **Importance:** The single most effective way to reduce baseline compute costs (up to 72% off).
*   **Core Functions:** Billing discount application.
*   **Architecture Interaction:** Applied automatically to Fargate and EC2 usage.
*   **Production Outcome:** Predictable base cost.
*   **Failure Impact:** Higher monthly bill (On-Demand rates).
*   **Scaling Behavior:** N/A.
*   **Security Considerations:** N/A.

#### B. Spot Instances (Fargate Spot)
*   **Definition:** Using AWS spare capacity for stateless tasks at steep discounts (up to 70%).
*   **Importance:** Excellent for handling bursty traffic or background processing cheaply.
*   **Core Functions:** Run tasks on spare hardware; handle interruption signals.
*   **Architecture Interaction:** ECS Service Capacity Provider Strategy.
*   **Production Outcome:** Massive cost reduction for non-critical/stateless workloads.
*   **Failure Impact:** Task termination with 2-minute warning.
*   **Scaling Behavior:** Highly elastic, but capacity is not guaranteed.
*   **Security Considerations:** N/A.

#### C. S3 Intelligent-Tiering
*   **Definition:** Storage class that monitors access patterns and moves objects between Frequent and Infrequent Access tiers.
*   **Importance:** Automates cost savings for Data Lake without operational overhead.
*   **Core Functions:** Access monitoring; automatic data transition.
*   **Architecture Interaction:** Bucket Lifecycle Policy.
*   **Production Outcome:** Lowest possible storage cost for unknown access patterns.
*   **Failure Impact:** None (Data remains accessible).
*   **Scaling Behavior:** N/A.
*   **Security Considerations:** N/A.

### 6.4 Architecture Flow Summary
1.  **Utilization:** Resources run (ECS, RDS).
2.  **Analysis:** AWS Cost Explorer detects trends.
3.  **Optimization:**
    *   Savings Plan covers the Base Load.
    *   Spot Instances cover the Peaks.
    *   Auto Scaling removes Unused resources.
4.  **Reporting:** AWS Budget alerting if forecasted spend > Threshold.

### 6.5 Operational Impact
*   **Performance:** Spot interruptions can cause minor jitter (task restarts).
*   **Availability:** High (Standard RIs guarantee capacity; Savings Plans do not).
*   **Security:** None.
*   **Cost:** Primary driver of ROI.

### 6.6 Best Practices
*   **Mix Strategies:** Use Savings Plans for baseline (min expected load) and Spot for scaling.
*   **Right Sizing:** Use Compute Optimizer to identify over-provisioned tasks before buying RIs.
*   **Tagging:** Enforce "CostCenter" tags to identify expensive teams/projects.

### 6.7 Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Spot Unavailable** | Capacity loss during peak | Use Capacity Provider Strategy (e.g., Base: 2 Fargate, Weight: 1 Spot). |
| **Over-commitment** | Wasted money on unused RIs | Buy RIs conservatively (cover 60-70% of baseline); scale up coverage slowly. |

---

## 7. High Availability & Disaster Recovery

### 7.1 Category Overview
This category ensures the system can withstand component failures (HA) and catastrophic region-wide events (DR). It relies on the "Multi-AZ everywhere" principle for HA and robust backup/replication strategies for DR.

### 7.2 Components / Tasks Table

| Component Name | Service Type | Purpose | AWS Service Used | Criticality Level |
| :--- | :--- | :--- | :--- | :--- |
| **Multi-AZ Architecture** | Design | Automatic failover during AZ loss | ALL (VPC, RDS, ECS) | Critical |
| **Automated Backups** | Managed | Data protection/snapshotting | AWS Backup | Critical |
| **Read Replicas** | Managed | Data redundancy & Read Scaling | Amazon Aurora | High |
| **Recovery Runbooks** | Process | Standard Operating Procedures | Documentation | High |

### 7.3 Detailed Component Documentation

#### A. Multi-AZ Deployment
*   **Definition:** Distributing resource instances across at least two physically separated Data Centers (AZs) within the Region.
*   **Importance:** Protects against fire, flood, or power loss affecting a single data center.
*   **Core Functions:** Load Balancing, Synchronous Replication (RDS), Cluster Awareness.
*   **Architecture Interaction:** ALB targets IPs in both AZs; RDS replicates to standby in alternate AZ.
*   **Production Outcome:** 99.9% - 99.99% Availability.
*   **Failure Impact:** If one AZ dies, valid traffic continues to the other AZ seamlessly.
*   **Scaling Behavior:** N/A.
*   **Security Considerations:** N/A.

#### B. AWS Backup & Snapshots
*   **Definition:** Centralized policy-based service to automate snapshots of RDS, DynamoDB, EFS, and EBS.
*   **Importance:** The last line of defense against data corruption or ransomware.
*   **Core Functions:** Scheduled backups; retention management; cross-region copy (optional).
*   **Architecture Interaction:** Hooks into storage services.
*   **Production Outcome:** RPO (Recovery Point Objective) of < 5-30 minutes.
*   **Failure Impact:** Data loss limited to the time since last snapshot/transaction log.
*   **Scaling Behavior:** N/A.
*   **Security Considerations:** Encrypt backups; Lock backup vault (WORM) to prevent deletion.

#### C. Recovery Runbooks
*   **Definition:** Step-by-step human instructions on how to restore services.
*   **Importance:** In a crisis, panic leads to errors. Checklists prevent errors.
*   **Core Functions:** Defining RTO/RPO; Listing restore commands.
*   **Architecture Interaction:** N/A.
*   **Production Outcome:** Predictable recovery times.
*   **Failure Impact:** Chaos and extended downtime during outages.
*   **Scaling Behavior:** N/A.
*   **Security Considerations:** Store runbooks off-platform (e.g., Notion/Google Drive) in case AWS is inaccessible.

### 7.4 Architecture Flow Summary
1.  **Normal Ops:** Data syncs to AZ-B; Backups taken nightly.
2.  **Incident:** AZ-A goes offline.
3.  **Failover:**
    *   RDS promotes Standby in AZ-B to Writer.
    *   ALB deregisters targets in AZ-A.
    *   ECS Scheduler launches replacement tasks in AZ-B.
4.  **Recovery:** System stabilizes in AZ-B automatically.

### 7.5 Operational Impact
*   **Performance:** Synchronous replication adds slight write latency (single digit ms).
*   **Availability:** Maximize uptime.
*   **Security:** Availability is a pillar of security (CIA triad).
*   **Cost:** Doubles infrastructure footprint (2x instances/subnets).

### 7.6 Best Practices
*   **Chaos Engineering:** Periodically simulate AZ failure in Staging.
*   **Cross-Region Copy:** Replicate critical backups to a different region (e.g., us-west-2) for true DR.
*   **Test Restores:** Frequently test restoring backups to ensure they are valid.

### 7.7 Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Corrupted Backup** | Cannot restore data | Verify backups automatically; enable checks. |
| **Logic Bug** | Deletes data in both AZs | Use "Delayed Replication" or Point-in-Time Recovery (PITR) to rewind time. |

---

