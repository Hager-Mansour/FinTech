# AWS Organizations & Tag Policy Enforcement Runbook

**Target Environment:** FinTech Global Platform – Production (`us-east-1`)
**Version:** 1.0
**Last Updated:** 2026-01-23
**Author:** Cloud Architecture Team

---

## 1. Executive Overview

### Business Objective
To establish a secure, compliant, and scalable multi-account AWS environment for the FinTech Global Platform. This foundation ensures isolation between production and non-production workloads, enforces strict cost governance through tagging, and mandates security guardrails at the organization root level.

### Security & Compliance Goals
- **SOC 2 Compliance:** Enforce least privilege, audit logging, and separation of duties.
- **Cost Governance:** Mandate cost allocation tags (`CostCenter`, `Project`, `Environment`) for all resources.
- **Data Sovereignty:** Restrict resource provisioning to the `us-east-1` region.
- **Account Isolation:** Isolate Workloads, Security, and Infrastructure into distinct Organizational Units (OUs).

---

## 2. Architecture Governance Model

### Organization Hierarchy
The following text-based hierarchy represents the target structure:

```
Root Account (Management)
├── Security OU
│   ├── Security-Audit Account (Log Archive & Auditing)
│   └── Security-Logging Account (Centralized CloudTrail/Config)
├── Infrastructure OU
│   ├── Shared-Services Account (CI/CD, Tooling)
│   └── Network-Hub Account (Transit Gateway, VPN)
├── Workloads OU
│   ├── Production OU
│   │   ├── Prod-US Account (Main Workload)
│   │   └── Prod-EU Account (Future Expansion/DR)
│   ├── Staging OU
│   │   └── Staging Account (Pre-Prod Testing)
│   └── Development OU
│       └── Dev Account (Sandbox/Dev Work)
└── Sandbox OU
    └── Sandbox Account (Experimental)
```

### Account Separation Strategy
- **Management Account:** Billing, SCP root, and Org management ONLY. No resources deployed here.
- **Security Accounts:** Restricted access. Aggregates logs and security findings.
- **Workload Accounts:** Where applications reside. Isolated by environment (Prod/Stage/Dev).

### Responsibility Boundaries
- **Cloud Center of Excellence (CCoE):** Owners of Root, SCPs, and Networking.
- **DevOps Team:** Owners of CI/CD and application deployment within Workload accounts.
- **SecOps Team:** Owners of Security OU and read-only audit access to all accounts.

---

## 3. Prerequisites

### Permissions Required
- Access to the **Management (Root) Account** with `AdministratorAccess` (restricted to CCoE leads).
- AWS CLI v2 installed and configured.
- `jq` installed for JSON parsing.

### Root Account Best Practices
- **MFA:** MFA enabled on the Root user and all IAM users with administrative privileges.
- **Contact Info:** Security and Operations contact details updated in Account Settings.
- **No Access Keys:** Root user must NOT have access keys.

---

## 4. Implementation Phases

### Phase 1: AWS Organizations Setup

**Objective:** Enable AWS Organizations with all features.

**CLI Steps:**
```bash
# Check if Organization exists (ensure you are acting as Management Account)
aws organizations describe-organization

# Create Organization (if not exists)
aws organizations create-organization --feature-set ALL
```

**Validation:**
- Command returns `Organization` details.
- Verify "MasterAccountArn" matches your current account.
- Verify "FeatureSet" is "ALL".

### Phase 2: Organizational Units (OUs) Creation

**Objective:** Create the directory structure.

**CLI Steps:**
```bash
# Get Root ID
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)

# Create OUs
aws organizations create-organizational-unit --parent-id $ROOT_ID --name "Security"
aws organizations create-organizational-unit --parent-id $ROOT_ID --name "Infrastructure"
aws organizations create-organizational-unit --parent-id $ROOT_ID --name "Workloads"
aws organizations create-organizational-unit --parent-id $ROOT_ID --name "Sandbox"

# Create Nested OUs for Workloads
WORKLOADS_ID=$(aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID --query 'OrganizationalUnits[?Name==`Workloads`].Id' --output text)

aws organizations create-organizational-unit --parent-id $WORKLOADS_ID --name "Production"
aws organizations create-organizational-unit --parent-id $WORKLOADS_ID --name "Staging"
aws organizations create-organizational-unit --parent-id $WORKLOADS_ID --name "Development"
```

**Validation:**
- Run `aws organizations list-organizational-units-for-parent --parent-id $ROOT_ID` to list top-level OUs.
- Run `aws organizations list-organizational-units-for-parent --parent-id $WORKLOADS_ID` to list nested OUs.

### Phase 3: Account Provisioning Process

**Objective:** Create member accounts. *Note: Email addresses must be unique.*

**CLI Steps:**
```bash
# Example: Create Security-Audit Account
aws organizations create-account \
  --email "secops+audit@fintech-global.com" \
  --account-name "Security-Audit" \
  --role-name "OrganizationAccountAccessRole" \
  --iam-user-access-to-billing "ALLOW"

# Repeat for other accounts (Log-Archive, Prod-US, Staging, Dev, etc.)
# Note the RequestId and check status:
aws organizations describe-create-account-status --create-account-request-id <REQUEST_ID>
```

**Post-Provisioning:**
- Move accounts to correct OUs.
```bash
# Move Account
aws organizations move-account \
  --account-id <ACCOUNT_ID> \
  --source-parent-id $ROOT_ID \
  --destination-parent-id <TARGET_OU_ID>
```

### Phase 4: SCP Security Guardrails Implementation

**Objective:** Apply immutable security policies.

**Policy 1: Deny Root User Access**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyRootUser",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    }
  ]
}
```

**Policy 2: Region Restriction (Allow us-east-1 only)**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNonApprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*", "organizations:*", "support:*", "sts:*", "route53:*", "cloudfront:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1"]
        }
      }
    }
  ]
}
```

**CLI Steps:**
```bash
# Create Policies
aws organizations create-policy --name "DenyRootUser" --type SERVICE_CONTROL_POLICY --content file://deny-root-scp.json
aws organizations create-policy --name "RegionRestriction" --type SERVICE_CONTROL_POLICY --content file://region-restriction-scp.json

# Attach to Root or OUs
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)
aws organizations attach-policy --policy-id <POLICY_ID> --target-id $ROOT_ID
```

**Validation:**
- Attempt to create an S3 bucket in `us-west-2` from a member account. It MUST fail with `AccessDenied`.
- Attempt to log in as Root in a member account and perform actions. It MUST fail.

### Phase 5: Tag Policy Enforcement

**Objective:** Standardize tags for cost tracking.

**Tag Policy (`tag-policy.json`):**
```json
{
  "tags": {
    "Environment": {
      "tag_key": { "@@assign": "Environment" },
      "tag_value": { "@@assign": ["Production", "Staging", "Development", "Sandbox"] },
      "enforced_for": { "@@assign": ["ec2:instance", "ec2:volume", "rds:db", "s3:bucket"] }
    },
    "Project": { "tag_key": { "@@assign": "Project" } },
    "CostCenter": { "tag_key": { "@@assign": "CostCenter" } },
    "Owner": { "tag_key": { "@@assign": "Owner" } }
  }
}
```

**CLI Steps:**
```bash
# Enable Tag Policies
aws organizations enable-policy-type --root-id $ROOT_ID --policy-type TAG_POLICY

# Create and Attach
aws organizations create-policy --name "FinTechTagPolicy" --type TAG_POLICY --content file://tag-policy.json
aws organizations attach-policy --policy-id <TAG_POLICY_ID> --target-id $ROOT_ID
```

### Phase 6: Consolidated Billing & Budget Setup

**Objective:** Centralize billing and alerting.

**Console Steps:**
1.  Navigate to **Billing Dashboard** > **Consolidated Billing**.
2.  Enable **Cost Allocation Tags** (activate `Environment`, `Project`, `CostCenter`, `Owner`).
3.  Go to **Budgets**.
4.  Create a **Cost Budget**:
    -   Amount: $10,000 (Monthly)
    -   Alerts: Notify `finops@fintech-global.com` at 50%, 80%, and 100% actual, and 100% forecasted.

**Validation:**
- Verify tags appear in Cost Explorer after 24 hours.
- Verify Budget state is `OK`.

### Phase 7: AWS Config Compliance Validation

**Objective:** continuous monitoring of compliance.

**CLI Steps:**
```bash
# Deploy Config Rule for Required Tags
aws configservice put-config-rule --config-rule '{
    "ConfigRuleName": "required-tags",
    "Source": {
      "Owner": "AWS",
      "SourceIdentifier": "REQUIRED_TAGS"
    },
    "InputParameters": "{\"tag1Key\":\"Environment\",\"tag2Key\":\"Project\",\"tag3Key\":\"CostCenter\",\"tag4Key\":\"Owner\"}"
}'
```

**Validation:**
- Check Config Dashboard. Non-compliant resources will be flagged RED.

### Phase 8: Well-Architected Tool Review

**Objective:** Document workload state.

**Steps:**
1.  Go to **Well-Architected Tool** in Console.
2.  **Define Workload:** "FinTech Global Platform".
3.  **Review Pillars:** Conduct review for Security, Reliability, Perf Efficiency, Cost Opt, Operational Excellence, and Sustainability.
4.  **Save Milestone:** Name it "Post-Launch-Baseline-v1.0".

---

## 5. Monitoring & Governance Validation

| Check | Method | Expected Result |
|-------|--------|-----------------|
| **SCP Enforcement** | Try to create VPC in `eu-west-1` | `AccessDenied` error |
| **Root Protection** | Log in as Root in Member Account | All actions Denied |
| **Tag Compliance** | Run `aws resourcegroupstaggingapi get-resources` | Resources have Environment, Project, CostCenter |
| **Budget Alert** | Simulate spend (optional) | Email received at threshold |

---

## 6. Security Best Practices

-   **Break-glass Access:** Store Root credentials in physical safe. Use only for emergencies.
-   **Least Privilege:** Users in member accounts assume roles (e.g., `OrganizationAccountAccessRole`) and do not have persistent IAM users.
-   **Logging:** All CloudTrail logs shipped to `Security-Audit` S3 bucket with MFA Delete enabled.

---

## 7. Compliance Mapping (SOC 2)

-   **CC6.1 (Logical Access):** Managed via SCPs denying Root and enforcing Role-based access.
-   **CC6.8 (Unauthorized Software):** Prevented via SCP software restrictions (if applicable) and Config rules.
-   **A1.2 (Change Management):** All Infrastructure changes deployed via CloudFormation/Terraform (Infrastructure as Code).

---

## 8. Failure Scenarios & Troubleshooting

### Scenario: SCP Misconfiguration (Locked out)
-   **Symptom:** Admins cannot perform legitimate actions.
-   **Fix:** Log in to Management Account (Root/Admin), detach the restrictive SCP from the OU/Account, and refine the JSON policy.
-   **Prevention:** Test SCPs on `Sandbox` OU first!

### Scenario: Account Creation Fails
-   **Symptom:** `CREATE_FAILED` status.
-   **Cause:** Email already used or limit reached.
-   **Fix:** Use unique email alias (e.g., `+prod` vs `+dev`). Request limit increase if needed.

---

## 9. Rollback & Recovery Procedures

### Rolling back a Tag Policy
```bash
# Detach the policy
aws organizations detach-policy --policy-id <POLICY_ID> --target-id <TARGET_ID>

# Delete policy (if needed)
aws organizations delete-policy --policy-id <POLICY_ID>
```

### Rolling back an SCP
1.  Identify the problematic SCP ID.
2.  Detach from the affected OU immediately to restore access.
3.  Analyze CloudTrail logs for `AccessDenied` events to understand the block.

---

## 10. Automation Opportunities

-   **Infrastructure as Code:** Use Terraform `aws_organizations_organization` resource to manage the entire hierarchy.
-   **Account Factory:** Use AWS Control Tower or Service Catalog to vend accounts with pre-approved networking and security baselines.

---

## 11. Post-Deployment Checklist

- [ ] Organization created with "All Features" enabled.
- [ ] OUs (Security, Infrastructure, Workloads, Sandbox) created.
- [ ] At least 5 accounts provisioned and moved to correct OUs.
- [ ] SCPs (Deny Root, Region Restriction) attached to Root/Workloads.
- [ ] Tag Policy created and attached.
- [ ] Consolidated Billing verified; Tax settings updated.
- [ ] AWS Budgets created for Project/Environment.
- [ ] AWS Config "required-tags" rule deployed in all regions/accounts.
- [ ] Well-Architected Baseline established.

**Approval:**
_Sign-off by CCoE Lead:_ ____________________
_Date:_ ____________________
