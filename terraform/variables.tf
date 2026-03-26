variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名（リソース名のプレフィックスに使用）"
  type        = string
  default     = "order-mgmt"
}

variable "env" {
  description = "環境名"
  type        = string
  default     = "dev"
}

# VPC
variable "vpc_cidr" {
  description = "VPC CIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネット CIDRブロック（ALB用、マルチAZ）"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネット CIDRブロック（ECS・RDS用、マルチAZ）"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# RDS
variable "db_name" {
  description = "データベース名"
  type        = string
  default     = "orderdb"
}

variable "db_username" {
  description = "DBユーザー名"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "DBパスワード（本番では AWS Secrets Manager を使うこと）"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDSインスタンスクラス"
  type        = string
  default     = "db.t3.micro"
}

# ECS
variable "order_service_image" {
  description = "order-service の ECR イメージURI"
  type        = string
}

variable "notification_service_image" {
  description = "notification-service の ECR イメージURI"
  type        = string
}

variable "order_service_cpu" {
  description = "order-service の CPU (vCPU × 1024)"
  type        = number
  default     = 512
}

variable "order_service_memory" {
  description = "order-service のメモリ (MB)"
  type        = number
  default     = 1024
}

variable "notification_service_cpu" {
  description = "notification-service の CPU"
  type        = number
  default     = 256
}

variable "notification_service_memory" {
  description = "notification-service のメモリ (MB)"
  type        = number
  default     = 512
}
