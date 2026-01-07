# =============================================================================
# Remote Backend Configuration - S3 + DynamoDB State Locking
# =============================================================================
# IMPORTANT: Before first use, run the bootstrap script to create:
#   - S3 bucket for state storage
#   - DynamoDB table for state locking
# See: terraform/bootstrap/README.md
# =============================================================================

terraform {
  backend "s3" {
    # These values are injected via -backend-config or backend.hcl
    # bucket         = "orthosense-terraform-state-${var.environment}"
    # key            = "orthosense/${var.environment}/terraform.tfstate"
    # region         = "eu-central-1"
    # dynamodb_table = "orthosense-terraform-locks"
    # encrypt        = true
  }
}
