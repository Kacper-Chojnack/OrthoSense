# =============================================================================
# Compute Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "apprunner_security_group_id" {
  description = "Security group ID for App Runner"
  type        = string
}

variable "cpu" {
  description = "CPU units for App Runner"
  type        = string
  default     = "1024"
}

variable "memory" {
  description = "Memory in MB for App Runner"
  type        = string
  default     = "2048"
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "max_concurrency" {
  description = "Maximum concurrent requests per instance"
  type        = number
  default     = 100
}

variable "database_url_secret_arn" {
  description = "ARN of DATABASE_URL secret"
  type        = string
}

variable "redis_url_secret_arn" {
  description = "ARN of REDIS_URL secret"
  type        = string
}

variable "secret_key" {
  description = "Application secret key"
  type        = string
  sensitive   = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "artifacts_bucket_name" {
  description = "Name of the S3 artifacts bucket"
  type        = string
  default     = ""
}

variable "allowed_cors_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = []
}

variable "allowed_hosts" {
  description = "List of allowed hosts"
  type        = list(string)
  default     = []
}

variable "create_apprunner_service" {
  description = "Whether to create App Runner service (set to false until Docker image is pushed to ECR)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
