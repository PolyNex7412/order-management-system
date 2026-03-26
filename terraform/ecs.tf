# ─────────────────────────────────────────
# ECS クラスター
# ─────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, { Name = "${local.name}-cluster" })
}

# ─────────────────────────────────────────
# IAM ロール（ECS タスク実行用）
# ECR からのイメージ pull・CloudWatch Logs への書き込みに必要
# ─────────────────────────────────────────
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─────────────────────────────────────────
# CloudWatch Logs グループ
# ─────────────────────────────────────────
resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/ecs/${local.name}/order-service"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "notification_service" {
  name              = "/ecs/${local.name}/notification-service"
  retention_in_days = 7

  tags = local.common_tags
}

# ─────────────────────────────────────────
# order-service タスク定義
# ─────────────────────────────────────────
resource "aws_ecs_task_definition" "order_service" {
  family                   = "${local.name}-order-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.order_service_cpu
  memory                   = var.order_service_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "order-service"
    image     = var.order_service_image
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "SPRING_DATASOURCE_URL"
        value = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}"
      },
      {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.db_username
      },
      {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value = var.db_password
      },
      {
        name  = "NOTIFICATION_SERVICE_URL"
        # ALB 経由でサービス間通信
        value = "http://${aws_lb.main.dns_name}"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.order_service.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = merge(local.common_tags, { Name = "${local.name}-td-order-service" })
}

# ─────────────────────────────────────────
# notification-service タスク定義
# ─────────────────────────────────────────
resource "aws_ecs_task_definition" "notification_service" {
  family                   = "${local.name}-notification-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.notification_service_cpu
  memory                   = var.notification_service_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "notification-service"
    image     = var.notification_service_image
    essential = true

    portMappings = [{
      containerPort = 8081
      protocol      = "tcp"
    }]

    environment = [{
      name  = "ConnectionStrings__DefaultConnection"
      value = "Host=${aws_db_instance.main.address};Database=${var.db_name};Username=${var.db_username};Password=${var.db_password}"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.notification_service.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = merge(local.common_tags, { Name = "${local.name}-td-notification-service" })
}

# ─────────────────────────────────────────
# ECS サービス（Fargate）
# ─────────────────────────────────────────
resource "aws_ecs_service" "order_service" {
  name            = "${local.name}-order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.order_service.arn
    container_name   = "order-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]

  tags = merge(local.common_tags, { Name = "${local.name}-svc-order-service" })
}

resource "aws_ecs_service" "notification_service" {
  name            = "${local.name}-notification-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.notification_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.notification_service.arn
    container_name   = "notification-service"
    container_port   = 8081
  }

  depends_on = [aws_lb_listener.http]

  tags = merge(local.common_tags, { Name = "${local.name}-svc-notification-service" })
}
