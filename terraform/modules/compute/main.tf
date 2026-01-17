# =============================================================================
# OrthoSense - Compute Module (App Runner + ECR)
# =============================================================================
# AWS App Runner for FastAPI Backend with VPC Connector
# Auto-scaling, environment variables from Secrets Manager
# =============================================================================

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "backend" {
  name                 = "${var.name_prefix}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend"
  })
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Secrets Manager - Application Secret Key
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "app_secret_key" {
  name        = "${var.name_prefix}-secret-key"
  description = "Application secret key for JWT signing"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-secret-key"
  })
}

resource "aws_secretsmanager_secret_version" "app_secret_key" {
  secret_id = aws_secretsmanager_secret.app_secret_key.id
  secret_string = jsonencode({
    SECRET_KEY = var.secret_key
  })
}

# -----------------------------------------------------------------------------
# App Runner VPC Connector
# -----------------------------------------------------------------------------

resource "aws_apprunner_vpc_connector" "main" {
  vpc_connector_name = "${var.name_prefix}-vpc-connector"
  subnets            = var.private_subnet_ids
  security_groups    = [var.apprunner_security_group_id]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc-connector"
  })
}

# -----------------------------------------------------------------------------
# App Runner Auto Scaling Configuration
# -----------------------------------------------------------------------------

resource "aws_apprunner_auto_scaling_configuration_version" "main" {
  auto_scaling_configuration_name = "${var.name_prefix}-autoscaling"

  min_size        = var.min_size
  max_size        = var.max_size
  max_concurrency = var.max_concurrency

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-autoscaling"
  })
}

# -----------------------------------------------------------------------------
# IAM Role for App Runner Instance
# -----------------------------------------------------------------------------

resource "aws_iam_role" "apprunner_instance" {
  name = "${var.name_prefix}-apprunner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "apprunner_secrets" {
  name = "${var.name_prefix}-apprunner-secrets-policy"
  role = aws_iam_role.apprunner_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.database_url_secret_arn,
          var.redis_url_secret_arn,
          aws_secretsmanager_secret.app_secret_key.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy" "apprunner_s3" {
  name = "${var.name_prefix}-apprunner-s3-policy"
  role = aws_iam_role.apprunner_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-artifacts",
          "arn:aws:s3:::${var.name_prefix}-artifacts/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM Role for App Runner Access (ECR)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "apprunner_access" {
  name = "${var.name_prefix}-apprunner-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# -----------------------------------------------------------------------------
# App Runner Observability Configuration
# -----------------------------------------------------------------------------

resource "aws_apprunner_observability_configuration" "main" {
  observability_configuration_name = "${var.name_prefix}-observability"

  trace_configuration {
    vendor = "AWSXRAY"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-observability"
  })
}

# -----------------------------------------------------------------------------
# App Runner Service
# Note: Only create when Docker image exists in ECR
# -----------------------------------------------------------------------------

resource "aws_apprunner_service" "backend" {
  count        = var.create_apprunner_service ? 1 : 0
  service_name = "${var.name_prefix}-backend"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access.arn
    }

    image_repository {
      image_configuration {
        port = "8000"

        runtime_environment_variables = {
          PROJECT_NAME                = "OrthoSense"
          ENVIRONMENT                 = var.environment
          API_V1_PREFIX               = "/api/v1"
          DEBUG                       = var.environment == "dev" ? "true" : "false"
          CORS_ORIGINS                = jsonencode(var.allowed_cors_origins)
          ALLOWED_HOSTS               = jsonencode(var.allowed_hosts)
          RATE_LIMIT_ENABLED          = "false" # Disabled - no Redis in VPC yet
          ACCESS_TOKEN_EXPIRE_MINUTES = "30"
          REFRESH_TOKEN_EXPIRE_DAYS   = "7"
          MAX_UPLOAD_SIZE_MB          = "100"
          SECRET_KEY                  = var.secret_key
        }

        # Use Secrets Manager for sensitive values
        runtime_environment_secrets = {
          DATABASE_URL = "${var.database_url_secret_arn}:DATABASE_URL::"
        }
      }

      image_identifier      = "${aws_ecr_repository.backend.repository_url}:latest"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = aws_iam_role.apprunner_instance.arn
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.main.arn

  # VPC enabled for RDS/Redis access
  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.main.arn
    }

    ingress_configuration {
      is_publicly_accessible = true
    }
  }

  observability_configuration {
    observability_configuration_arn = aws_apprunner_observability_configuration.main.arn
    observability_enabled           = true
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend"
  })

  depends_on = [
    aws_iam_role_policy.apprunner_secrets,
    aws_iam_role_policy.apprunner_s3,
    aws_iam_role_policy_attachment.apprunner_ecr
  ]
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group for App Runner
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "apprunner" {
  name              = "/aws/apprunner/${var.name_prefix}-backend"
  retention_in_days = 90

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-apprunner-logs"
  })
}
