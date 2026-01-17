# =============================================================================
# OrthoSense - Cache Module (ElastiCache Redis)
# =============================================================================
# Redis for Rate Limiting & Session Caching
# Encryption at rest (KMS) and in transit (TLS)
# =============================================================================

# -----------------------------------------------------------------------------
# Random Auth Token for Redis
# -----------------------------------------------------------------------------

resource "random_password" "redis_auth" {
  length  = 64
  special = false
}

# -----------------------------------------------------------------------------
# Secrets Manager - Redis Auth Token
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "redis_auth" {
  name        = "${var.name_prefix}-redis-auth"
  description = "ElastiCache Redis auth token"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-auth"
  })
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis_auth.result
}

# -----------------------------------------------------------------------------
# Secrets Manager - REDIS_URL for Application
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "redis_url" {
  name        = "${var.name_prefix}-redis-url"
  description = "Redis connection URL for application"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-url"
  })
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id = aws_secretsmanager_secret.redis_url.id
  secret_string = jsonencode({
    REDIS_URL = "rediss://:${random_password.redis_auth.result}@${aws_elasticache_replication_group.main.primary_endpoint_address}:6379/0"
  })
}

# -----------------------------------------------------------------------------
# ElastiCache Parameter Group
# -----------------------------------------------------------------------------

resource "aws_elasticache_parameter_group" "main" {
  name        = "${var.name_prefix}-redis7-params"
  family      = "redis7"
  description = "Redis 7.x parameters for OrthoSense"

  # Memory management
  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  # Connection timeout
  parameter {
    name  = "timeout"
    value = "300"
  }

  # Enable keyspace notifications for cache invalidation
  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis7-params"
  })
}

# -----------------------------------------------------------------------------
# ElastiCache Replication Group (Cluster Mode Disabled)
# -----------------------------------------------------------------------------

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.name_prefix}-redis"
  description          = "Redis replication group for OrthoSense rate limiting"

  # Engine configuration
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.main.name
  port                 = 6379

  # Network configuration
  subnet_group_name  = var.subnet_group_name
  security_group_ids = var.security_group_ids

  # High availability (disabled for single node)
  automatic_failover_enabled = var.num_cache_nodes > 1
  multi_az_enabled           = var.num_cache_nodes > 1

  # Security - Encryption
  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result

  # Maintenance
  maintenance_window        = "sun:05:00-sun:06:00"
  snapshot_window           = "04:00-05:00"
  snapshot_retention_limit  = var.snapshot_retention_limit
  final_snapshot_identifier = var.environment == "prod" ? "${var.name_prefix}-redis-final" : null

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Apply changes immediately in non-prod
  apply_immediately = var.environment != "prod"

  # Notification topic (optional)
  # notification_topic_arn = var.sns_topic_arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis"
  })

  lifecycle {
    ignore_changes = [
      num_cache_clusters
    ]
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms for ElastiCache
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.name_prefix}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Redis CPU utilization exceeds 75%"

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.name_prefix}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis memory usage exceeds 80%"

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_connections" {
  alarm_name          = "${var.name_prefix}-redis-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "Redis current connections exceed 1000"

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }

  tags = var.tags
}
