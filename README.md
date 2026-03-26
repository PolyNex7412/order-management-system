# 受注管理システム / Order Management System

業務システム開発のポートフォリオとして作成した、マイクロサービス構成の受注管理APIです。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────┐
│                    AWS (ap-northeast-1)              │
│                                                      │
│  Internet ──► ALB (パスベースルーティング)            │
│                 │                                    │
│    /api/orders  │  /api/notifications                │
│    /api/products│  /notification/*                   │
│         ▼       │        ▼                           │
│  ┌─────────────┐│ ┌─────────────────┐               │
│  │order-service││ │notification-    │               │
│  │(Java/Spring)││ │service (.NET)   │               │
│  └──────┬──────┘│ └────────┬────────┘               │
│         │       │          │                         │
│         └───────┴──────────┘                         │
│                      │                               │
│              ┌───────▼────────┐                      │
│              │ RDS PostgreSQL │                      │
│              └────────────────┘                      │
│                                                      │
│  [パブリックサブネット] ALB                           │
│  [プライベートサブネット] ECS Fargate / RDS           │
└─────────────────────────────────────────────────────┘
```

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| Backend (受注サービス) | Java 17 / Spring Boot 3.2 |
| Backend (通知サービス) | C# / ASP.NET Core 8 |
| データベース | PostgreSQL 15 |
| マイグレーション | Flyway |
| ORM | Spring Data JPA (Java) / Entity Framework Core (C#) |
| API仕様 | OpenAPI 3.0 / Swagger UI |
| インフラ | AWS (ECS Fargate / RDS / ALB / ECR) |
| IaC | Terraform |
| コンテナ | Docker / Docker Compose |
| CI/CD | GitHub Actions |

## DB設計

```
customers          products
─────────────      ─────────────────
id (PK)            id (PK)
name               name
email (UNIQUE)     price
address            stock_quantity  ← CHECK (>= 0)
created_at         created_at
updated_at         updated_at

orders                        order_items
──────────────────────        ──────────────────────────────
id (PK)                       id (PK)
customer_id (FK)              order_id (FK)
status                        product_id (FK)
  PENDING                     quantity
  CONFIRMED                   unit_price  ← 受注時点の価格を保持
  CANCELLED                   subtotal    (GENERATED ALWAYS AS quantity * unit_price)
total_amount
created_at / updated_at

notifications  ← notification-service が書き込む
──────────────────
id (PK)
order_id (FK)
type  (ORDER_CONFIRMED / ORDER_CANCELLED)
message
created_at
```

**設計のポイント：**
- `order_items.unit_price` は受注確定時の価格を保持（商品価格変動への対応）
- `products.stock_quantity` に CHECK 制約でマイナス在庫を DB レベルで防止
- インデックスを `orders.status`・`order_items.order_id` 等に設定しクエリを最適化

## 主要な業務ロジック

### 在庫引当（受注登録）

```
POST /api/orders
  1. 顧客存在チェック
  2. 商品ごとに SELECT FOR UPDATE（悲観的ロック）で在庫取得
  3. 在庫不足 → 409 Conflict を返す
  4. stock_quantity を減算
  5. unit_price = 受注時点の商品価格で OrderItem を生成
  6. 合計金額を計算して保存
```

悲観的ロックにより、同時に複数の受注が入っても在庫のマイナスが発生しない。

### 受注確定とサービス間通信

```
POST /api/orders/{id}/confirm
  1. PENDING → CONFIRMED にステータス遷移
  2. notification-service へ HTTP POST
  3. 通知失敗は受注処理に影響しない（try/catch でログ出力のみ）
```

notification-service への通知は**ベストエフォート**とし、通知の失敗が受注確定を妨げない設計。

## API エンドポイント

### order-service (`:8080`)

| メソッド | パス | 説明 |
|---|---|---|
| GET | `/api/orders` | 受注一覧 |
| GET | `/api/orders/{id}` | 受注詳細 |
| POST | `/api/orders` | 受注登録（在庫引当） |
| POST | `/api/orders/{id}/confirm` | 受注確定 |
| POST | `/api/orders/{id}/cancel` | 受注キャンセル（在庫戻し） |
| GET | `/api/products` | 商品一覧 |
| POST | `/api/products` | 商品登録 |
| GET | `/api/customers` | 顧客一覧 |
| POST | `/api/customers` | 顧客登録 |

### notification-service (`:8081`)

| メソッド | パス | 説明 |
|---|---|---|
| GET | `/api/notifications` | 通知ログ一覧 |
| GET | `/api/notifications/order/{orderId}` | 受注IDで通知ログ取得 |
| POST | `/api/notifications` | 通知受信（order-service から呼ばれる） |

## ローカル起動

```bash
# 全サービスを起動（初回はビルドに数分かかります）
docker compose up --build

# 起動確認
# order-service Swagger UI
open http://localhost:8080/swagger-ui.html

# notification-service Swagger UI
open http://localhost:8081/swagger
```

## AWS デプロイ手順

### 1. Terraform でインフラ構築

```bash
cd terraform

# tfvars を作成
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集して db_password を設定

terraform init
terraform plan
terraform apply
```

### 2. ECR に Docker イメージをプッシュ

```bash
# ECR ログイン
aws ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com

# order-service
docker build -t order-mgmt-dev-order-service services/order-service/
docker tag  order-mgmt-dev-order-service:latest \
  <ECR_URL>/order-mgmt-dev-order-service:latest
docker push <ECR_URL>/order-mgmt-dev-order-service:latest

# notification-service
docker build -t order-mgmt-dev-notification-service services/notification-service/
docker tag  order-mgmt-dev-notification-service:latest \
  <ECR_URL>/order-mgmt-dev-notification-service:latest
docker push <ECR_URL>/order-mgmt-dev-notification-service:latest
```

### 3. ECS サービスを更新

```bash
aws ecs update-service \
  --cluster order-mgmt-dev-cluster \
  --service order-mgmt-dev-order-service \
  --force-new-deployment

aws ecs update-service \
  --cluster order-mgmt-dev-cluster \
  --service order-mgmt-dev-notification-service \
  --force-new-deployment
```

### 4. GitHub Actions による自動デプロイ（2回目以降）

`services/order-service/` 以下を変更して `main` にプッシュすると自動でデプロイされます。

**必要な GitHub Secrets：**

| Secret | 内容 |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM ユーザーのアクセスキー |
| `AWS_SECRET_ACCESS_KEY` | IAM ユーザーのシークレットキー |
| `TF_DB_PASSWORD` | RDS パスワード（terraform-plan.yml 用） |

### 5. 使い終わったらリソース削除

```bash
terraform destroy
```

## インフラ構成

```
VPC (10.0.0.0/16)
  ├── パブリックサブネット × 2AZ
  │     └── ALB（インターネット向け）
  │     └── NAT Gateway
  └── プライベートサブネット × 2AZ
        ├── ECS Fargate（order-service / notification-service）
        └── RDS PostgreSQL（暗号化・自動バックアップ）

セキュリティグループ
  ALB  → ECS のみ許可
  ECS  → RDS のみ許可（5432番ポート）
  RDS  → ECS SG からのみ許可
```
