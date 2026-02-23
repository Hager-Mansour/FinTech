# AWS Budget
resource "aws_budgets_budget" "monthly" {
  name              = "fintech-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "100"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_12:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["team-platform@company.com"]
  }
}

/*
# Cost Anomaly Detection
resource "aws_ce_anomaly_monitor" "main" {
  name              = "FinTechAnomalyMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "main" {
  name      = "FinTechAnomalySubscription"
  frequency = "DAILY"
  monitor_arn_list = [
    aws_ce_anomaly_monitor.main.arn
  ]

  subscriber {
    type    = "EMAIL"
    address = "team-platform@company.com"
  }
}
*/
