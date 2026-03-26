# ALB 本体（パブリックサブネットに配置）
resource "aws_lb" "main" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, { Name = "${local.name}-alb" })
}

# ─────────────────────────────────────────
# ターゲットグループ
# ─────────────────────────────────────────

resource "aws_lb_target_group" "order_service" {
  name        = "${local.name}-tg-order"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Fargate は ip 指定

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = merge(local.common_tags, { Name = "${local.name}-tg-order" })
}

resource "aws_lb_target_group" "notification_service" {
  name        = "${local.name}-tg-notif"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = merge(local.common_tags, { Name = "${local.name}-tg-notif" })
}

# ─────────────────────────────────────────
# リスナー + パスベースルーティング
# /api/notifications* → notification-service
# それ以外           → order-service（デフォルト）
# ─────────────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # デフォルトアクション：order-service へ転送
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_service.arn
  }
}

resource "aws_lb_listener_rule" "notification_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/api/notifications*", "/notification/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notification_service.arn
  }
}
