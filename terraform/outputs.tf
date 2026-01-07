# =============================================================================
# OrthoSense Infrastructure - Root Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Networking Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.database.rds_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = module.database.rds_port
}

output "database_url_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DATABASE_URL"
  value       = module.database.database_url_secret_arn
}

# -----------------------------------------------------------------------------
# Redis Outputs
# -----------------------------------------------------------------------------

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.cache.redis_endpoint
  sensitive   = true
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = module.cache.redis_port
}

output "redis_url_secret_arn" {
  description = "ARN of the Secrets Manager secret containing REDIS_URL"
  value       = module.cache.redis_url_secret_arn
}

# -----------------------------------------------------------------------------
# App Runner Outputs
# -----------------------------------------------------------------------------

output "apprunner_service_url" {
  description = "App Runner service URL"
  value       = module.compute.apprunner_service_url
}

output "apprunner_service_arn" {
  description = "App Runner service ARN"
  value       = module.compute.apprunner_service_arn
}

output "ecr_repository_url" {
  description = "ECR repository URL for backend images"
  value       = module.compute.ecr_repository_url
}

# -----------------------------------------------------------------------------
# Frontend Outputs
# -----------------------------------------------------------------------------

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend assets"
  value       = module.cdn.frontend_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cdn.cloudfront_domain_name
}

# -----------------------------------------------------------------------------
# Storage Outputs
# -----------------------------------------------------------------------------

output "artifacts_bucket_name" {
  description = "S3 bucket name for artifacts/uploads"
  value       = module.storage.artifacts_bucket_name
}

output "artifacts_bucket_arn" {
  description = "S3 bucket ARN for artifacts"
  value       = module.storage.artifacts_bucket_arn
}

# -----------------------------------------------------------------------------
# Security Outputs
# -----------------------------------------------------------------------------

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = module.security.github_actions_role_arn
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = module.security.kms_key_arn
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------

output "cloudwatch_log_group_apprunner" {
  description = "CloudWatch log group for App Runner"
  value       = module.monitoring.cloudwatch_log_group_apprunner
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.cloudwatch_dashboard_url
}
