# =============================================================================
# OrthoSense - Terraform Bootstrap
# =============================================================================
# One-time setup for S3 backend and DynamoDB lock table
# Run this BEFORE initializing main Terraform configuration
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "OrthoSense"
      ManagedBy = "terraform-bootstrap"
      Purpose   = "terraform-state"
    }
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environments" {
  description = "List of environments to create state buckets for"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

# -----------------------------------------------------------------------------
# S3 Buckets for Terraform State
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  for_each = toset(var.environments)

  bucket = "orthosense-terraform-state-${each.key}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "orthosense-terraform-state-${each.key}"
    Environment = each.key
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  for_each = toset(var.environments)

  bucket = aws_s3_bucket.terraform_state[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  for_each = toset(var.environments)

  bucket = aws_s3_bucket.terraform_state[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  for_each = toset(var.environments)

  bucket = aws_s3_bucket.terraform_state[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  for_each = toset(var.environments)

  bucket = aws_s3_bucket.terraform_state[each.key].id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# -----------------------------------------------------------------------------
# DynamoDB Table for State Locking
# -----------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "orthosense-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "orthosense-terraform-locks"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "state_bucket_arns" {
  description = "ARNs of state buckets"
  value       = { for k, v in aws_s3_bucket.terraform_state : k => v.arn }
}

output "lock_table_name" {
  description = "DynamoDB lock table name"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "initialization_commands" {
  description = "Commands to initialize Terraform for each environment"
  value = {
    for env in var.environments :
    env => "cd ../.. && terraform init -backend-config=environments/${env}/backend.hcl"
  }
}
