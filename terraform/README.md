# Terraform Infrastructure

This directory contains the Terraform configuration for OrthoSense AWS infrastructure.

## Directory Structure

```
terraform/
├── main.tf                 # Root module - orchestrates all modules
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Terraform and provider versions
├── backend.tf              # Remote state configuration
├── bootstrap/              # One-time setup for state backend
│   ├── main.tf
│   └── README.md
├── environments/           # Environment-specific configurations
│   ├── dev/
│   │   ├── backend.hcl
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── backend.hcl
│   │   └── terraform.tfvars
│   └── prod/
│       ├── backend.hcl
│       └── terraform.tfvars
└── modules/                # Reusable infrastructure modules
    ├── networking/         # VPC, subnets, security groups
    ├── database/           # RDS PostgreSQL
    ├── cache/              # ElastiCache Redis
    ├── compute/            # App Runner, ECR
    ├── storage/            # S3 buckets
    ├── cdn/                # CloudFront, S3 frontend
    ├── security/           # KMS, IAM, OIDC
    └── monitoring/         # CloudWatch
```

## Quick Start

1. **Bootstrap** (one-time):
   ```bash
   cd bootstrap && terraform init && terraform apply
   ```

2. **Initialize** for an environment:
   ```bash
   terraform init -backend-config=environments/dev/backend.hcl
   ```

3. **Plan**:
   ```bash
   terraform plan -var-file=environments/dev/terraform.tfvars -var="secret_key=YOUR_SECRET"
   ```

4. **Apply**:
   ```bash
   terraform apply -var-file=environments/dev/terraform.tfvars -var="secret_key=YOUR_SECRET"
   ```

## Modules

| Module | Description |
|--------|-------------|
| `networking` | VPC, public/private/database subnets, NAT Gateway, VPC Flow Logs |
| `database` | RDS PostgreSQL 16 with Multi-AZ, encryption, automated backups |
| `cache` | ElastiCache Redis 7 with TLS, auth token, encryption |
| `compute` | App Runner service, ECR repository, auto-scaling |
| `storage` | S3 bucket for artifacts with lifecycle rules |
| `cdn` | CloudFront distribution, S3 frontend bucket, OAC |
| `security` | KMS key, GitHub OIDC, IAM roles, WAF (prod) |
| `monitoring` | CloudWatch log groups, dashboard, alarms, SNS |

## Security Features

- ✅ All data encrypted at rest (KMS)
- ✅ All data encrypted in transit (TLS 1.2+)
- ✅ VPC Flow Logs for network auditing
- ✅ GitHub OIDC (no long-lived credentials)
- ✅ Least-privilege IAM policies
- ✅ WAF with OWASP rules (production)
- ✅ Private subnets for database tier

## Documentation

See [DEPLOY.md](../DEPLOY.md) for comprehensive deployment guide.
