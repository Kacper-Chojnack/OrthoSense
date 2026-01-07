# =============================================================================
# OrthoSense - CDN Module (CloudFront + S3 Frontend)
# =============================================================================
# CloudFront distribution with Origin Access Control (OAC)
# S3 bucket for Flutter Web static files
# TLS 1.2 minimum, HTTP/2 enabled
# =============================================================================

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.us_east_1]
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket - Frontend Static Files
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.name_prefix}-frontend"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-frontend"
  })
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# CloudFront Origin Access Control (OAC)
# -----------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.name_prefix}-frontend-oac"
  description                       = "OAC for frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - Allow CloudFront OAC Only
# Note: Using account-level CloudFront ARN pattern to avoid circular dependency
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringLike = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
          }
        }
      },
      {
        Sid       = "EnforceHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudFront Cache Policy
# -----------------------------------------------------------------------------

resource "aws_cloudfront_cache_policy" "frontend" {
  name        = "${var.name_prefix}-frontend-cache-policy"
  comment     = "Cache policy for Flutter Web assets"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# -----------------------------------------------------------------------------
# CloudFront Response Headers Policy (Security Headers)
# -----------------------------------------------------------------------------

resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${var.name_prefix}-security-headers"
  comment = "Security headers for GDPR compliance"

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    content_security_policy {
      content_security_policy = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' https://*.orthosense.app https://*.amazonaws.com; frame-ancestors 'none';"
      override                = true
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      override = true
      value    = "camera=(self), microphone=(), geolocation=()"
    }
  }
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "OrthoSense frontend distribution"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = var.domain_name != "" ? [var.domain_name] : []

  # Origin: S3 Frontend
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # Origin: App Runner Backend API (only if URL is provided)
  dynamic "origin" {
    for_each = var.apprunner_url != "" ? [1] : []
    content {
      domain_name = replace(var.apprunner_url, "https://", "")
      origin_id   = "AppRunner-Backend"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Default behavior: S3 (Frontend)
  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-Frontend"
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    cache_policy_id          = aws_cloudfront_cache_policy.frontend.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  # API behavior: App Runner (Backend) - only if App Runner is deployed
  dynamic "ordered_cache_behavior" {
    for_each = var.apprunner_url != "" ? [1] : []
    content {
      path_pattern             = "/api/*"
      allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods           = ["GET", "HEAD"]
      target_origin_id         = "AppRunner-Backend"
      viewer_protocol_policy   = "redirect-to-https"
      compress                 = true

      # No caching for API
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer

      response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
    }
  }

  # Health check endpoint (no cache) - only if App Runner is deployed
  dynamic "ordered_cache_behavior" {
    for_each = var.apprunner_url != "" ? [1] : []
    content {
      path_pattern             = "/health"
      allowed_methods          = ["GET", "HEAD"]
      cached_methods           = ["GET", "HEAD"]
      target_origin_id         = "AppRunner-Backend"
      viewer_protocol_policy   = "redirect-to-https"
      compress                 = true
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    }
  }

  # SPA fallback: all unknown paths -> index.html
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  # SSL Configuration
  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == ""
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate.main[0].arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Geo-restrictions (GDPR: EU focus)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Note: CloudFront logging disabled - enable after creating dedicated logs bucket
  # logging_config {
  #   bucket          = "${var.name_prefix}-logs.s3.amazonaws.com"
  #   prefix          = "cloudfront-logs/"
  #   include_cookies = false
  # }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cloudfront"
  })

  depends_on = [aws_s3_bucket_policy.frontend]
}

# -----------------------------------------------------------------------------
# ACM Certificate (only if domain_name is provided)
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "main" {
  count    = var.domain_name != "" ? 1 : 0
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-certificate"
  })
}

# -----------------------------------------------------------------------------
# CloudFront Function for URL Rewriting (SPA Support)
# -----------------------------------------------------------------------------

resource "aws_cloudfront_function" "spa_rewrite" {
  name    = "${var.name_prefix}-spa-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "URL rewriting for SPA routing"
  publish = true

  code = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // Check if the URI has a file extension
      if (uri.includes('.')) {
        return request;
      }

      // Redirect to index.html for SPA routing
      if (!uri.endsWith('/')) {
        request.uri = '/index.html';
      }

      return request;
    }
  EOF
}
