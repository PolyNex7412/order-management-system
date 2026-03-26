# ECR リポジトリ（Docker イメージの保管場所）
# GitHub Actions から push → ECS がここから pull する

resource "aws_ecr_repository" "order_service" {
  name                 = "${local.name}-order-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, { Name = "${local.name}-ecr-order-service" })
}

resource "aws_ecr_repository" "notification_service" {
  name                 = "${local.name}-notification-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, { Name = "${local.name}-ecr-notification-service" })
}

# 古いイメージを自動削除（直近5世代を保持）
resource "aws_ecr_lifecycle_policy" "order_service" {
  repository = aws_ecr_repository.order_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "最新5イメージを保持"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "notification_service" {
  repository = aws_ecr_repository.notification_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "最新5イメージを保持"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}
