# =============================================================================
# OrthoSense - Development Environment Variables
# =============================================================================

# General
aws_region  = "eu-central-1"
app_name    = "orthosense"
environment = "dev"

# Networking - Cost optimized
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2
enable_nat_gateway       = true
single_nat_gateway       = true # Single NAT for cost savings

# Database - Dev settings
db_instance_class          = "db.t4g.micro"
db_allocated_storage       = 20
db_max_allocated_storage   = 50
db_name                    = "orthosense_dev"
db_username                = "orthosense_admin"
db_multi_az                = false # Single AZ for dev
db_backup_retention_period = 7     # Shorter retention for dev
db_deletion_protection     = false # Allow deletion in dev

# Redis - Dev settings
redis_node_type                = "cache.t4g.micro"
redis_num_cache_nodes          = 1
redis_engine_version           = "7.1"
redis_snapshot_retention_limit = 1

# App Runner - Dev settings
apprunner_cpu             = "512"
apprunner_memory          = "1024"
apprunner_min_size        = 1
apprunner_max_size        = 2
apprunner_max_concurrency = 50

# Security
allowed_cors_origins = [
  "http://localhost:8080",
  "http://localhost:3000",
  "http://127.0.0.1:8080"
]

allowed_hosts = [
  "localhost",
  "127.0.0.1",
  "*"
]

# Monitoring
enable_enhanced_monitoring = false # Disabled for cost savings
log_retention_days         = 30

# GitHub
github_org  = "Kacper-Chojnack"
github_repo = "OrthoSense"

# App Runner
create_apprunner_service = true # App Runner service is already deployed

# Tags
project_tags = {
  CostCenter   = "Development"
  Owner        = "DevTeam"
  AutoShutdown = "true"
}
