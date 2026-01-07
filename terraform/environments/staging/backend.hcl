# =============================================================================
# OrthoSense - Staging Environment Configuration
# =============================================================================
# Production-like settings for pre-release testing
# Multi-AZ enabled, production instance sizes
# =============================================================================

# Backend configuration
bucket         = "orthosense-terraform-state-staging"
key            = "orthosense/staging/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "orthosense-terraform-locks"
encrypt        = true
