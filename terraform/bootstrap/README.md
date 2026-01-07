# Terraform Bootstrap - State Infrastructure

This directory contains the one-time setup for Terraform remote state management.

## Purpose

Creates:
- S3 buckets for Terraform state (one per environment: dev, staging, prod)
- DynamoDB table for state locking
- Encryption and versioning for state files

## Usage

### 1. Initialize Bootstrap

```bash
cd terraform/bootstrap
terraform init
```

### 2. Apply Bootstrap Configuration

```bash
terraform apply
```

### 3. Initialize Main Terraform

After bootstrap is complete, initialize the main Terraform configuration:

```bash
# For development
cd ..
terraform init -backend-config=environments/dev/backend.hcl

# For staging
terraform init -backend-config=environments/staging/backend.hcl -reconfigure

# For production
terraform init -backend-config=environments/prod/backend.hcl -reconfigure
```

## Important Notes

- Run bootstrap **only once** per AWS account
- The S3 buckets have `prevent_destroy = true` lifecycle rule
- State files are encrypted with AWS KMS
- Old state versions are retained for 90 days

## Cleanup

⚠️ **WARNING**: Do not destroy bootstrap resources while other Terraform configurations depend on them!

```bash
# Only if you're absolutely sure:
terraform destroy
```
