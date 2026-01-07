# =============================================================================
# OrthoSense - Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development/testing
# Single AZ, smaller instances, relaxed security for debugging
# =============================================================================

# Backend configuration
bucket         = "orthosense-terraform-state-dev"
key            = "orthosense/dev/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "orthosense-terraform-locks"
encrypt        = true
