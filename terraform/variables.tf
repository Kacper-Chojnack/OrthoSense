# =============================================================================
# OrthoSense Infrastructure - Root Variables
# =============================================================================
# Medical Application - GDPR/RODO Compliant
# =============================================================================

# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for infrastructure deployment (eu-central-1 for GDPR compliance)"
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^eu-", var.aws_region))
    error_message = "For GDPR compliance, AWS region must be in EU (eu-*)."
  }
}

variable "app_name" {
  description = "Application name used for resource naming"
  type        = string
  default     = "orthosense"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.app_name))
    error_message = "App name must be lowercase alphanumeric with hyphens, 3-21 chars."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Networking Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones_count" {
  description = "Number of availability zones to use (min 2 for Multi-AZ)"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zones_count >= 2 && var.availability_zones_count <= 3
    error_message = "AZ count must be between 2 and 3."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost savings for non-prod)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "orthosense"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "orthosense_admin"
  sensitive   = true
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Days to retain automated backups (GDPR: min 30 for medical)"
  type        = number
  default     = 35

  validation {
    condition     = var.db_backup_retention_period >= 7
    error_message = "Backup retention must be at least 7 days."
  }
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Redis Configuration
# -----------------------------------------------------------------------------

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes (1 for cluster mode disabled)"
  type        = number
  default     = 1
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "redis_snapshot_retention_limit" {
  description = "Days to retain Redis snapshots"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# App Runner Configuration
# -----------------------------------------------------------------------------

variable "apprunner_cpu" {
  description = "CPU units for App Runner (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "1024"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.apprunner_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "apprunner_memory" {
  description = "Memory in MB for App Runner (512, 1024, 2048, 3072, 4096, ...)"
  type        = string
  default     = "2048"

  validation {
    condition     = contains(["512", "1024", "2048", "3072", "4096", "6144", "8192", "10240", "12288"], var.apprunner_memory)
    error_message = "Memory must be a valid App Runner memory configuration."
  }
}

variable "apprunner_min_size" {
  description = "Minimum number of App Runner instances"
  type        = number
  default     = 1
}

variable "apprunner_max_size" {
  description = "Maximum number of App Runner instances"
  type        = number
  default     = 10
}

variable "apprunner_max_concurrency" {
  description = "Maximum concurrent requests per instance before scaling"
  type        = number
  default     = 100
}



# -----------------------------------------------------------------------------
# Security & Secrets Configuration
# -----------------------------------------------------------------------------

variable "secret_key" {
  description = "Application secret key for JWT signing (min 32 chars)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.secret_key) >= 32
    error_message = "Secret key must be at least 32 characters."
  }
}

variable "allowed_cors_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = []
}

variable "allowed_hosts" {
  description = "List of allowed hosts for TrustedHostMiddleware"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring for RDS"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Domain Configuration
# -----------------------------------------------------------------------------

variable "app_domain" {
  description = "Application domain for CORS and external access (e.g., 'orthosense.app')"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC Configuration
# -----------------------------------------------------------------------------

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

# NOTE:
# - The default below is the current GitHub OIDC provider thumbprint for
#   token.actions.githubusercontent.com.
# - To retrieve the latest thumbprint, you can run (on a system with openssl):
#     openssl s_client -servername token.actions.githubusercontent.com \
#       -connect token.actions.githubusercontent.com:443 </dev/null 2>/dev/null | \
#       openssl x509 -fingerprint -sha1 -noout | sed 's/://g' | tr 'A-Z' 'a-z'
# - Re-check this value periodically (for example during security reviews) or
#   whenever GitHub updates their OIDC configuration documentation.
variable "github_oidc_thumbprint" {
  description = "GitHub OIDC provider thumbprint (updated periodically; see comments above for how to refresh)"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

# -----------------------------------------------------------------------------
# App Runner Configuration
# -----------------------------------------------------------------------------

variable "create_apprunner_service" {
  description = "Whether to create App Runner service (set to true after Docker image is pushed to ECR)"
  type        = bool
  default     = false
}
