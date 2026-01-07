# =============================================================================
# CDN Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name (empty for CloudFront default)"
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "Subdomain for API"
  type        = string
  default     = "api"
}

variable "apprunner_url" {
  description = "App Runner service URL"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
