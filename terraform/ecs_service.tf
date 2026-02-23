# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/fintech-api"
  retention_in_days = 30
}

# ECS Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = "fintech-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "api-container"
      image = "${aws_ecr_repository.api.repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        },
        {
          name      = "API_KEY"
          valueFrom = aws_secretsmanager_secret.api_keys.arn
        },
        {
          name      = "REDIS_AUTH_TOKEN"
          valueFrom = aws_secretsmanager_secret.redis_auth.arn
        }
      ]
      environment = [
        { name = "ENVIRONMENT", value = "production" },
        { name = "REGION", value = var.aws_region },
        { name = "AWS_XRAY_SDK_ENABLED", value = "true" },
        { name = "DB_HOST", value = aws_rds_cluster.main.endpoint },
        { name = "DB_NAME", value = aws_rds_cluster.main.database_name },
        { name = "DB_USER", value = aws_rds_cluster.main.master_username },
        { name = "REDIS_HOST", value = aws_elasticache_replication_group.main.primary_endpoint_address }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "xray-daemon"
      image     = "amazon/aws-xray-daemon"
      cpu       = 32
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "xray"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "fintech-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_app[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}

# ECS Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 3
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
