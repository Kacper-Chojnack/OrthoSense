# OrthoSense Deployment Guide

> **Production-Grade AWS Infrastructure for Medical Telerehabilitation Application**
> 
> GDPR/RODO Compliant | Encryption Everywhere | Zero Long-Lived Keys

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Environment Configuration](#environment-configuration)
5. [Deployment Procedures](#deployment-procedures)
6. [CI/CD Pipelines](#cicd-pipelines)
7. [Security & Compliance](#security--compliance)
8. [Monitoring & Observability](#monitoring--observability)
9. [Troubleshooting](#troubleshooting)
10. [Cost Optimization](#cost-optimization)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud (eu-central-1)                        │
│                                  GDPR Compliant                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                                                                              │
│                                                                              │
│                              Mobile App (iOS)                                │
│                                     │                                        │
│                                     │ HTTPS /api/*                           │
│                                     ▼                                        │
│    ┌──────────────┐         ┌─────────────────────────────────────────┐    │
│    │  App Runner  │────────▶│           ECR Repository                 │    │
│    │  (FastAPI)   │         │     - Vulnerability Scanning             │    │
│    │  Auto-scale  │         │     - KMS Encryption                     │    │
│    └──────┬───────┘         └─────────────────────────────────────────┘    │
│           │                                                                  │
│           │ VPC Connector                                                    │
│           ▼                                                                  │
│    ┌─────────────────────────────────────────────────────────────────┐     │
│    │                         Private Subnets                          │     │
│    │  ┌─────────────────┐              ┌────────────────────────┐   │     │
│    │  │ RDS PostgreSQL  │              │   ElastiCache Redis    │   │     │
│    │  │ - Multi-AZ      │              │   - Rate Limiting      │   │     │
│    │  │ - KMS Encrypted │              │   - TLS + Auth Token   │   │     │
│    │  │ - 35-day backup │              │   - KMS Encrypted      │   │     │
│    │  └─────────────────┘              └────────────────────────┘   │     │
│    └─────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│    ┌─────────────────────────────────────────────────────────────────┐     │
│    │                      Security & Monitoring                       │     │
│    │  - KMS Customer Managed Key    - CloudWatch Logs & Alarms       │     │
│    │  - Secrets Manager             - VPC Flow Logs                  │     │
│    │  - GitHub OIDC Provider        - SNS Notifications              │     │
│    │  - WAF (OWASP Rules)           - Performance Insights           │     │
│    └─────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Service | Purpose |
|-----------|---------|---------|

| **Backend** | App Runner | FastAPI containerized service |
| **Database** | RDS PostgreSQL 16 | Primary data store (Multi-AZ) |
| **Cache** | ElastiCache Redis 7 | Rate limiting & session cache |
| **Registry** | ECR | Docker image repository |
| **Secrets** | Secrets Manager | DATABASE_URL, REDIS_URL, SECRET_KEY |
| **Encryption** | KMS | Customer-managed encryption key |
| **Monitoring** | CloudWatch | Logs, metrics, alarms, dashboards |

---

## Prerequisites

### Required Tools

```bash
# Terraform >= 1.6.0
brew install terraform

# AWS CLI v2
brew install awscli

# Docker (for local testing)
brew install --cask docker

# Flutter (for frontend builds)
brew install --cask flutter
```

### AWS Account Setup

1. **AWS Account** with administrative access
2. **Route 53** hosted zone (if using custom domain)
3. **SES** verified domain (for email notifications)

### GitHub Repository Secrets

Configure these secrets in your GitHub repository settings:

| Secret | Description |
|--------|-------------|
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account ID |
| `APP_SECRET_KEY` | Application secret key (min 32 chars) |
| `CODECOV_TOKEN` | Codecov upload token |


---

## Initial Setup

### Step 1: Bootstrap Terraform Backend

First, create the S3 buckets and DynamoDB table for Terraform state:

```bash
cd terraform/bootstrap

# Initialize and apply
terraform init
terraform apply

# Note the output - you'll need it for next steps
```

### Step 2: Update GitHub Organization

Edit the environment files to set your GitHub organization:

```bash
# Edit all environment files
for env in dev staging prod; do
  sed -i '' 's/YOUR_GITHUB_ORG/your-actual-org/' \
    terraform/environments/$env/terraform.tfvars
done
```

### Step 3: Generate Application Secret

```bash
# Generate a secure 64-character secret key
openssl rand -base64 48

# Add to GitHub Secrets as APP_SECRET_KEY
```

### Step 4: Initialize Terraform for Development

```bash
cd terraform

# Initialize with dev backend
terraform init -backend-config=environments/dev/backend.hcl

# Review the plan
terraform plan -var-file=environments/dev/terraform.tfvars \
  -var="secret_key=YOUR_64_CHAR_SECRET"

# Apply (first deployment)
terraform apply -var-file=environments/dev/terraform.tfvars \
  -var="secret_key=YOUR_64_CHAR_SECRET"
```

### Step 5: Push Initial Docker Image

Before App Runner can start, push an initial image to ECR:

```bash
# Get ECR login
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com

# Build and push
cd backend
docker build -t orthosense-dev-backend .
docker tag orthosense-dev-backend:latest \
  YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/orthosense-dev-backend:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/orthosense-dev-backend:latest
```

---

## Environment Configuration

### Development (Cost Optimized)

```hcl
# Key settings for dev
db_instance_class     = "db.t4g.micro"
db_multi_az           = false
redis_node_type       = "cache.t4g.micro"
apprunner_min_size    = 1
apprunner_max_size    = 2
single_nat_gateway    = true
```

**Estimated Monthly Cost**: ~$80-120

### Staging (Production-Like)

```hcl
# Key settings for staging
db_instance_class     = "db.t4g.small"
db_multi_az           = true
redis_node_type       = "cache.t4g.small"
apprunner_min_size    = 1
apprunner_max_size    = 5
single_nat_gateway    = false
```

**Estimated Monthly Cost**: ~$200-300

### Production (Full HA)

```hcl
# Key settings for production
db_instance_class     = "db.t4g.medium"
db_multi_az           = true
redis_num_cache_nodes = 2
apprunner_min_size    = 2
apprunner_max_size    = 10
availability_zones    = 3
```

**Estimated Monthly Cost**: ~$400-600

---

## Deployment Procedures

### Backend Deployment

#### Automatic (via CI/CD)

1. Push to `develop` branch → Deploys to **Dev**
2. Push to `main` branch → Deploys to **Staging** → Manual approval → **Production**

#### Manual Deployment

```bash
# Using GitHub Actions workflow dispatch
gh workflow run deploy-backend.yml \
  -f environment=prod

# Or via AWS CLI
aws apprunner start-deployment \
  --service-arn arn:aws:apprunner:eu-central-1:ACCOUNT:service/orthosense-prod-backend
```



### Infrastructure Changes

```bash
# Plan changes
terraform plan -var-file=environments/prod/terraform.tfvars \
  -var="secret_key=$APP_SECRET_KEY"

# Apply with approval
terraform apply -var-file=environments/prod/terraform.tfvars \
  -var="secret_key=$APP_SECRET_KEY"
```

---

## CI/CD Pipelines

### Pipeline Overview

| Workflow | Trigger | Actions |
|----------|---------|---------|
| `deploy-backend.yml` | Push to backend/ | Lint → Test → Build → Deploy |
| `deploy-frontend.yml` | Push to lib/ | Analyze → Build → Deploy |
| `terraform.yml` | Push to terraform/ | Validate → Security → Plan → Apply |

### GitHub Environments

Configure these environments in GitHub Settings → Environments:

| Environment | Protection Rules |
|-------------|------------------|
| `dev` | None |
| `staging` | Required reviewers (optional) |
| `prod` | Required reviewers, deployment branches: `main` |

### OIDC Configuration

The infrastructure uses GitHub OIDC for keyless authentication:

```yaml
# No long-lived AWS keys needed!
- name: Configure AWS credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/orthosense-prod-github-actions-role
    aws-region: eu-central-1
```

---

## Security & Compliance

### Encryption Standards

| Data Type | Encryption | Key Management |
|-----------|------------|----------------|
| Data at Rest (RDS) | AES-256 | Customer KMS Key |
| Data at Rest (S3) | AES-256 | Customer KMS Key |
| Data at Rest (Redis) | AES-256 | Customer KMS Key |
| Data in Transit | TLS 1.2+ | AWS Managed |
| Secrets | AES-256 | Customer KMS Key |

### GDPR/RODO Compliance Checklist

- [x] **Data Location**: All data stored in EU (eu-central-1)
- [x] **Encryption**: All data encrypted at rest and in transit
- [x] **Backup Retention**: 35-day automated backups
- [x] **Audit Logs**: VPC Flow Logs, CloudTrail enabled
- [x] **Access Control**: IAM with least-privilege policies
- [x] **Data Isolation**: Private subnets for database layer

### Security Headers

CloudFront automatically adds these headers:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; ...
```

---

## Monitoring & Observability

### CloudWatch Dashboard

Access the dashboard at:
```
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=orthosense-prod-dashboard
```

### Key Metrics

| Metric | Warning | Critical |
|--------|---------|----------|
| App Runner Latency (p95) | > 1s | > 2s |
| App Runner 5xx Errors | > 5/5min | > 10/5min |
| RDS CPU | > 70% | > 80% |
| RDS Connections | > 100 | > 150 |
| Redis Memory | > 70% | > 80% |

### Alerts

Alerts are sent to the configured email address via SNS:

```hcl
# In terraform.tfvars
alarm_email = "alerts@orthosense.app"
```

### Log Access

```bash
# App Runner logs
aws logs tail /aws/apprunner/orthosense-prod-backend/application --follow

# RDS PostgreSQL logs
aws logs tail /aws/rds/instance/orthosense-prod-postgres/postgresql --follow
```

---

## Troubleshooting

### Common Issues

#### App Runner Deployment Fails

```bash
# Check deployment status
aws apprunner describe-service \
  --service-arn arn:aws:apprunner:eu-central-1:ACCOUNT:service/orthosense-prod-backend

# Check logs
aws logs tail /aws/apprunner/orthosense-prod-backend/service --follow
```

#### Database Connection Issues

```bash
# Verify security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=orthosense-prod-*"

# Test from App Runner (via logs)
# Check for "connection refused" or "timeout" errors
```

#### Redis Connection Issues

```bash
# Get Redis endpoint
aws elasticache describe-replication-groups \
  --replication-group-id orthosense-prod-redis

# Verify auth token in Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id orthosense-prod-redis-url
```

### Rollback Procedures

#### Backend Rollback

```bash
# List recent images
aws ecr describe-images \
  --repository-name orthosense-prod-backend \
  --query 'imageDetails[*].[imageTags,imagePushedAt]' \
  --output table

# Update App Runner to previous image tag
# (Requires manual update in console or Terraform)
```

#### Frontend Rollback

```bash
# S3 versioning allows rollback
aws s3api list-object-versions \
  --bucket orthosense-prod-frontend \
  --prefix index.html

# Restore previous version
aws s3api copy-object \
  --bucket orthosense-prod-frontend \
  --copy-source orthosense-prod-frontend/index.html?versionId=PREVIOUS_VERSION \
  --key index.html
```

#### Terraform Rollback

```bash
# Terraform state is versioned in S3
# List state versions
aws s3api list-object-versions \
  --bucket orthosense-terraform-state-prod \
  --prefix orthosense/prod/terraform.tfstate
```

---

## Cost Optimization

### Development Environment

- Use `single_nat_gateway = true` (saves ~$30/month)
- Disable `db_multi_az` (saves ~$15/month)
- Use `apprunner_min_size = 1` (pay only when used)
- Set `enable_enhanced_monitoring = false`

### Scheduling

Consider shutting down non-production environments outside business hours:

```bash
# Stop App Runner (scales to 0)
# RDS can be stopped for up to 7 days
aws rds stop-db-instance --db-instance-identifier orthosense-dev-postgres
```

### Reserved Capacity

For production, consider:
- **RDS Reserved Instances**: Up to 60% savings
- **ElastiCache Reserved Nodes**: Up to 55% savings

---

## Support

- **Infrastructure Issues**: Create issue with `infra` label
- **Security Concerns**: Email security@orthosense.app
- **Emergency**: Contact on-call via PagerDuty

---

*Last Updated: January 2026*
*Terraform Version: 1.6.6*
*AWS Provider Version: ~> 5.30*
