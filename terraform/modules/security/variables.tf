# =============================================================================
# Security Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_oidc_thumbprint" {
  description = "GitHub OIDC provider thumbprint"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN (optional - will use wildcard if not provided)"
  type        = string
  default     = ""
}

variable "artifacts_bucket_arn" {
  description = "S3 artifacts bucket ARN (optional - will use wildcard if not provided)"
  type        = string
  default     = ""
}

variable "frontend_bucket_arn" {
  description = "S3 frontend bucket ARN (optional - will use wildcard if not provided)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
