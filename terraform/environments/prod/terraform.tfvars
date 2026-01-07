# =============================================================================
# OrthoSense - Production Environment Variables
# =============================================================================
# GDPR/RODO Compliant - Medical Application
# =============================================================================

# General
aws_region  = "eu-central-1"
app_name    = "orthosense"
environment = "prod"

# Networking - Full HA
vpc_cidr                 = "10.2.0.0/16"
availability_zones_count = 3
enable_nat_gateway       = true
single_nat_gateway       = false  # HA NAT per AZ

# Database - Production
db_instance_class          = "db.t4g.medium"
db_allocated_storage       = 100
db_max_allocated_storage   = 500
db_name                    = "orthosense_prod"
db_username                = "orthosense_admin"
db_multi_az                = true   # Multi-AZ required
db_backup_retention_period = 35     # GDPR: 35 days
db_deletion_protection     = true   # Prevent accidental deletion

# Redis - Production
redis_node_type              = "cache.t4g.medium"
redis_num_cache_nodes        = 2     # Replication for HA
redis_engine_version         = "7.1"
redis_snapshot_retention_limit = 7

# App Runner - Production
apprunner_cpu             = "1024"
apprunner_memory          = "2048"
apprunner_min_size        = 2      # Minimum 2 for HA
apprunner_max_size        = 10
apprunner_max_concurrency = 100

# Frontend
domain_name            = "orthosense.app"
api_subdomain          = "api"
cloudfront_price_class = "PriceClass_100"  # EU-focused

# Security
allowed_cors_origins = [
  "https://orthosense.app",
  "https://www.orthosense.app"
]

allowed_hosts = [
  "orthosense.app",
  "www.orthosense.app",
  "api.orthosense.app"
]

# Monitoring
enable_enhanced_monitoring = true
log_retention_days         = 90    # GDPR requirement
alarm_email                = "alerts@orthosense.app"

# GitHub
github_org  = "kacper-chojnack"
github_repo = "OrthoSense"

# Tags
project_tags = {
  CostCenter     = "Production"
  Owner          = "Platform"
  Compliance     = "GDPR-RODO"
  DataRetention  = "35-days"
  BackupPolicy   = "Daily"
}
