# =============================================================================
# OrthoSense - Production Environment Configuration
# =============================================================================
# Full production settings - GDPR compliant
# Multi-AZ, enhanced monitoring, maximum security
# =============================================================================

# Backend configuration
bucket         = "orthosense-terraform-state-prod"
key            = "orthosense/prod/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "orthosense-terraform-locks"
encrypt        = true
