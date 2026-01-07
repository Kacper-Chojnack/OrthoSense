# =============================================================================
# Monitoring Module - Outputs
# =============================================================================

output "cloudwatch_log_group_apprunner" {
  description = "CloudWatch log group for App Runner application logs"
  value       = aws_cloudwatch_log_group.apprunner.name
}

output "cloudwatch_log_group_rds" {
  description = "CloudWatch log group for RDS"
  value       = "/aws/rds/instance/${var.rds_instance_id}/postgresql"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.name_prefix}-dashboard"
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
