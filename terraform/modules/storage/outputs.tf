# =============================================================================
# Storage Module - Outputs
# =============================================================================

output "artifacts_bucket_name" {
  description = "S3 artifacts bucket name"
  value       = aws_s3_bucket.artifacts.id
}

output "artifacts_bucket_arn" {
  description = "S3 artifacts bucket ARN"
  value       = aws_s3_bucket.artifacts.arn
}

output "artifacts_bucket_domain" {
  description = "S3 artifacts bucket regional domain name"
  value       = aws_s3_bucket.artifacts.bucket_regional_domain_name
}

output "logs_bucket_name" {
  description = "S3 logs bucket name"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "S3 logs bucket ARN"
  value       = aws_s3_bucket.logs.arn
}
