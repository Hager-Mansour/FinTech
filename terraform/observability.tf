# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "FinTech-Operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "TargetResponseTime", ".", ".", { stat = "p99" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Traffic and Latency"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.main.name, "ClusterName", aws_ecs_cluster.main.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Service Resource Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", aws_rds_cluster.main.cluster_identifier],
            [".", "DatabaseConnections", ".", "."],
            [".", "AuroraReplicaLag", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Cluster Performance"
        }
      }
    ]
  })
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alerts" {
  name = "fintech-alerts"
}

# CloudWatch Alarm: High Latency
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "fintech-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.2" # 200ms
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# CloudWatch Alarm: ECS CPU High
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "fintech-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# CloudWatch Alarm: ECS Memory High
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "fintech-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# CloudWatch Alarm: 5XX Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "fintech-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High 5XX error count from targets"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# CloudWatch Alarm: Unhealthy Targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "fintech-unhealthy-tasks"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "At least one target is unhealthy"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.api.arn_suffix
  }
}

# CloudWatch Alarm: RDS Connections
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "fintech-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "High number of database connections"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }
}
