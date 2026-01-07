# =============================================================================
# OrthoSense Infrastructure - Main Configuration
# =============================================================================
# Medical Application - GDPR/RODO Compliant Infrastructure
# Author: OrthoSense DevOps Team
# =============================================================================

# -----------------------------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Project     = var.app_name
        Environment = var.environment
        ManagedBy   = "terraform"
        Compliance  = "GDPR-RODO"
        Application = "OrthoSense"
      },
      var.project_tags
    )
  }
}

# Secondary provider for CloudFront ACM certificates (must be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = merge(
      {
        Project     = var.app_name
        Environment = var.environment
        ManagedBy   = "terraform"
        Compliance  = "GDPR-RODO"
        Application = "OrthoSense"
      },
      var.project_tags
    )
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# Local Variables
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.app_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id

  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    var.availability_zones_count
  )

  # CIDR calculations for subnets
  public_subnets = [
    for i in range(var.availability_zones_count) :
    cidrsubnet(var.vpc_cidr, 8, i)
  ]

  private_subnets = [
    for i in range(var.availability_zones_count) :
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]

  database_subnets = [
    for i in range(var.availability_zones_count) :
    cidrsubnet(var.vpc_cidr, 8, i + 20)
  ]

  # Environment-specific settings
  is_production = var.environment == "prod"

  common_tags = {
    DataClassification = "PHI-Medical"
    CostCenter         = "Engineering"
  }
}

# -----------------------------------------------------------------------------
# Module: Networking (VPC, Subnets, Security Groups)
# -----------------------------------------------------------------------------

module "networking" {
  source = "./modules/networking"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  availability_zones  = local.azs
  public_subnets      = local.public_subnets
  private_subnets     = local.private_subnets
  database_subnets    = local.database_subnets
  enable_nat_gateway  = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  environment         = var.environment

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Security (KMS, IAM, OIDC)
# -----------------------------------------------------------------------------

module "security" {
  source = "./modules/security"

  name_prefix            = local.name_prefix
  environment            = var.environment
  account_id             = local.account_id
  github_org             = var.github_org
  github_repo            = var.github_repo
  github_oidc_thumbprint = var.github_oidc_thumbprint
  # Note: Using wildcard ARNs in security module to avoid circular dependencies
  # ecr_repository_arn, artifacts_bucket_arn, frontend_bucket_arn are optional

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Database (RDS PostgreSQL)
# -----------------------------------------------------------------------------

module "database" {
  source = "./modules/database"

  name_prefix              = local.name_prefix
  environment              = var.environment
  vpc_id                   = module.networking.vpc_id
  database_subnet_ids      = module.networking.database_subnet_ids
  allowed_security_groups  = [module.networking.apprunner_security_group_id]
  db_subnet_group_name     = module.networking.db_subnet_group_name
  security_group_ids       = [module.networking.rds_security_group_id]

  instance_class           = var.db_instance_class
  allocated_storage        = var.db_allocated_storage
  max_allocated_storage    = var.db_max_allocated_storage
  db_name                  = var.db_name
  db_username              = var.db_username
  multi_az                 = local.is_production ? var.db_multi_az : false
  backup_retention_period  = var.db_backup_retention_period
  deletion_protection      = local.is_production ? var.db_deletion_protection : false
  kms_key_arn              = module.security.kms_key_arn
  enable_enhanced_monitoring = var.enable_enhanced_monitoring

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Cache (ElastiCache Redis)
# -----------------------------------------------------------------------------

module "cache" {
  source = "./modules/cache"

  name_prefix              = local.name_prefix
  environment              = var.environment
  vpc_id                   = module.networking.vpc_id
  private_subnet_ids       = module.networking.private_subnet_ids
  allowed_security_groups  = [module.networking.apprunner_security_group_id]
  subnet_group_name        = module.networking.elasticache_subnet_group_name
  security_group_ids       = [module.networking.redis_security_group_id]

  node_type                = var.redis_node_type
  num_cache_nodes          = var.redis_num_cache_nodes
  engine_version           = var.redis_engine_version
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  kms_key_arn              = module.security.kms_key_arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Storage (S3 Artifacts Bucket)
# -----------------------------------------------------------------------------

module "storage" {
  source = "./modules/storage"

  name_prefix  = local.name_prefix
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Module: Compute (App Runner + ECR)
# -----------------------------------------------------------------------------

module "compute" {
  source = "./modules/compute"

  name_prefix    = local.name_prefix
  environment    = var.environment
  aws_region     = var.aws_region
  account_id     = local.account_id

  # VPC Configuration for App Runner
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  apprunner_security_group_id = module.networking.apprunner_security_group_id

  # App Runner Configuration
  cpu             = var.apprunner_cpu
  memory          = var.apprunner_memory
  min_size        = var.apprunner_min_size
  max_size        = var.apprunner_max_size
  max_concurrency = var.apprunner_max_concurrency

  # Environment Variables & Secrets
  database_url_secret_arn = module.database.database_url_secret_arn
  redis_url_secret_arn    = module.cache.redis_url_secret_arn
  secret_key              = var.secret_key
  kms_key_arn             = module.security.kms_key_arn

  # Application Configuration
  allowed_cors_origins = var.allowed_cors_origins
  allowed_hosts        = var.allowed_hosts

  # App Runner creation flag
  create_apprunner_service = var.create_apprunner_service

  tags = local.common_tags

  depends_on = [
    module.networking,
    module.database,
    module.cache,
    module.security
  ]
}



# -----------------------------------------------------------------------------
# Module: Monitoring (CloudWatch)
# -----------------------------------------------------------------------------

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix         = local.name_prefix
  environment         = var.environment
  aws_region          = var.aws_region
  log_retention_days  = var.log_retention_days
  alarm_email         = var.alarm_email

  apprunner_service_name = module.compute.apprunner_service_name
  rds_instance_id        = module.database.rds_instance_id
  redis_cluster_id       = module.cache.redis_cluster_id

  tags = local.common_tags
}
