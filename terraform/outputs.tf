output "alb_dns_name" {
  description = "ALBのDNS名（アプリへのアクセスURL）"
  value       = "http://${aws_lb.main.dns_name}"
}

output "order_service_swagger_url" {
  description = "order-service Swagger UI"
  value       = "http://${aws_lb.main.dns_name}/swagger-ui.html"
}

output "notification_service_swagger_url" {
  description = "notification-service Swagger UI"
  value       = "http://${aws_lb.main.dns_name}/notification/swagger"
}

output "ecr_order_service_url" {
  description = "order-service ECRリポジトリURL"
  value       = aws_ecr_repository.order_service.repository_url
}

output "ecr_notification_service_url" {
  description = "notification-service ECRリポジトリURL"
  value       = aws_ecr_repository.notification_service.repository_url
}

output "rds_endpoint" {
  description = "RDSエンドポイント"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECSクラスター名"
  value       = aws_ecs_cluster.main.name
}
