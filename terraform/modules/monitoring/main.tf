# =============================================================================
# OrthoSense - Monitoring Module (CloudWatch)
# =============================================================================
# Log groups, dashboards, alarms for observability
# GDPR compliant logging with appropriate retention
# =============================================================================

# -----------------------------------------------------------------------------
# CloudWatch Log Group - App Runner
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "apprunner" {
  name              = "/aws/apprunner/${var.name_prefix}-backend/application"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-apprunner-logs"
  })
}

resource "aws_cloudwatch_log_group" "apprunner_service" {
  name              = "/aws/apprunner/${var.name_prefix}-backend/service"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-apprunner-service-logs"
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group - RDS (created automatically by RDS, we just reference it)
# -----------------------------------------------------------------------------

# Note: RDS creates this log group automatically when logs are enabled
# We skip creating it to avoid conflicts
# data "aws_cloudwatch_log_group" "rds_postgresql" {
#   name = "/aws/rds/instance/${var.rds_instance_id}/postgresql"
# }

# -----------------------------------------------------------------------------
# SNS Topic for Alarms
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "alarms" {
  name = "${var.name_prefix}-alarms"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alarms"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms - App Runner
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "apprunner_5xx_errors" {
  alarm_name          = "${var.name_prefix}-apprunner-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxStatusResponses"
  namespace           = "AWS/AppRunner"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "App Runner 5xx errors exceed threshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ServiceName = var.apprunner_service_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "apprunner_latency" {
  alarm_name          = "${var.name_prefix}-apprunner-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "RequestLatency"
  namespace           = "AWS/AppRunner"
  period              = 300
  extended_statistic  = "p95"
  threshold           = 2000 # 2 seconds
  alarm_description   = "App Runner p95 latency exceeds 2 seconds"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ServiceName = var.apprunner_service_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "apprunner_active_instances" {
  alarm_name          = "${var.name_prefix}-apprunner-scaling-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ActiveInstances"
  namespace           = "AWS/AppRunner"
  period              = 300
  statistic           = "Average"
  threshold           = 8
  alarm_description   = "App Runner active instances approaching max (8/10)"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ServiceName = var.apprunner_service_name
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: App Runner Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "App Runner - Request Count"
          region = var.aws_region
          metrics = [
            ["AWS/AppRunner", "Requests", "ServiceName", var.apprunner_service_name, { stat = "Sum", period = 300 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "App Runner - Latency (p95)"
          region = var.aws_region
          metrics = [
            ["AWS/AppRunner", "RequestLatency", "ServiceName", var.apprunner_service_name, { stat = "p95", period = 300 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "App Runner - Error Rate"
          region = var.aws_region
          metrics = [
            ["AWS/AppRunner", "5xxStatusResponses", "ServiceName", var.apprunner_service_name, { stat = "Sum", period = 300, color = "#d62728" }],
            [".", "4xxStatusResponses", ".", ".", { stat = "Sum", period = 300, color = "#ff7f0e" }]
          ]
          view = "timeSeries"
        }
      },
      # Row 2: RDS Metrics
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "RDS - CPU Utilization"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id, { stat = "Average", period = 300 }]
          ]
          view  = "timeSeries"
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "RDS - Database Connections"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id, { stat = "Average", period = 300 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "RDS - Free Storage Space"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_id, { stat = "Average", period = 300 }]
          ]
          view = "timeSeries"
        }
      },
      # Row 3: Redis Metrics
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "Redis - CPU Utilization"
          region = var.aws_region
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", var.redis_cluster_id, { stat = "Average", period = 300 }]
          ]
          view  = "timeSeries"
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "Redis - Memory Usage"
          region = var.aws_region
          metrics = [
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", var.redis_cluster_id, { stat = "Average", period = 300 }]
          ]
          view  = "timeSeries"
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "Redis - Cache Hits/Misses"
          region = var.aws_region
          metrics = [
            ["AWS/ElastiCache", "CacheHits", "CacheClusterId", var.redis_cluster_id, { stat = "Sum", period = 300, color = "#2ca02c" }],
            [".", "CacheMisses", ".", ".", { stat = "Sum", period = 300, color = "#d62728" }]
          ]
          view = "timeSeries"
        }
      },
      # Row 4: App Runner Scaling
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "App Runner - Active Instances"
          region = var.aws_region
          metrics = [
            ["AWS/AppRunner", "ActiveInstances", "ServiceName", var.apprunner_service_name, { stat = "Average", period = 60 }]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "App Runner - Concurrent Requests"
          region = var.aws_region
          metrics = [
            ["AWS/AppRunner", "ConcurrentRequests", "ServiceName", var.apprunner_service_name, { stat = "Average", period = 60 }]
          ]
          view = "timeSeries"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Metric Filters
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "error_logs" {
  name           = "${var.name_prefix}-error-logs"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.apprunner.name

  metric_transformation {
    name      = "ErrorCount"
    namespace = "OrthoSense/Application"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "auth_failures" {
  name           = "${var.name_prefix}-auth-failures"
  pattern        = "\"401\" OR \"403\" OR \"authentication failed\""
  log_group_name = aws_cloudwatch_log_group.apprunner.name

  metric_transformation {
    name      = "AuthFailures"
    namespace = "OrthoSense/Security"
    value     = "1"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Alarm - Custom Metrics
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.name_prefix}-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorCount"
  namespace           = "OrthoSense/Application"
  period              = 300
  statistic           = "Sum"
  threshold           = 50
  alarm_description   = "Application error count exceeds 50 in 5 minutes"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "auth_failure_spike" {
  alarm_name          = "${var.name_prefix}-auth-failures-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AuthFailures"
  namespace           = "OrthoSense/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Authentication failures spike detected"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  tags = var.tags
}
