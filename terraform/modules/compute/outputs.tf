# =============================================================================
# Compute Module - Outputs
# =============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.backend.arn
}

output "apprunner_service_url" {
  description = "App Runner service URL"
  value       = var.create_apprunner_service ? aws_apprunner_service.backend[0].service_url : ""
}

output "apprunner_service_arn" {
  description = "App Runner service ARN"
  value       = var.create_apprunner_service ? aws_apprunner_service.backend[0].arn : ""
}

output "apprunner_service_id" {
  description = "App Runner service ID"
  value       = var.create_apprunner_service ? aws_apprunner_service.backend[0].service_id : ""
}

output "apprunner_service_name" {
  description = "App Runner service name"
  value       = "${var.name_prefix}-backend"
}

output "apprunner_instance_role_arn" {
  description = "App Runner instance role ARN"
  value       = aws_iam_role.apprunner_instance.arn
}

output "app_secret_key_arn" {
  description = "ARN of the application secret key"
  value       = aws_secretsmanager_secret.app_secret_key.arn
}
