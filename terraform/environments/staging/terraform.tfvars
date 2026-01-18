# =============================================================================
# OrthoSense - Staging Environment Variables
# =============================================================================

# General
aws_region  = "eu-central-1"
app_name    = "orthosense"
environment = "staging"

# Networking - Production-like
vpc_cidr                 = "10.1.0.0/16"
availability_zones_count = 2
enable_nat_gateway       = true
single_nat_gateway       = false # HA NAT

# Database - Production-like
db_instance_class          = "db.t4g.small"
db_allocated_storage       = 50
db_max_allocated_storage   = 100
db_name                    = "orthosense_staging"
db_username                = "orthosense_admin"
db_multi_az                = true # Multi-AZ enabled
db_backup_retention_period = 14   # 2 weeks retention
db_deletion_protection     = true

# Redis - Production-like
redis_node_type                = "cache.t4g.small"
redis_num_cache_nodes          = 1
redis_engine_version           = "7.1"
redis_snapshot_retention_limit = 3

# App Runner - Production-like
apprunner_cpu             = "1024"
apprunner_memory          = "2048"
apprunner_min_size        = 1
apprunner_max_size        = 5
apprunner_max_concurrency = 80

# Frontend
cloudfront_price_class = "PriceClass_100"

# Security
allowed_cors_origins = [
  "https://staging.orthosense.app"
]

allowed_hosts = [
  "staging.orthosense.app",
  "api-staging.orthosense.app"
]

# Monitoring
enable_enhanced_monitoring = true
log_retention_days         = 60

# GitHub
github_org  = "Kacper-Chojnack"
github_repo = "OrthoSense"

# Tags
project_tags = {
  CostCenter = "Staging"
  Owner      = "DevOps"
}
