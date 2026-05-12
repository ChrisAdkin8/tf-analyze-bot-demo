terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Seed bug #1 — image_scanning_configuration.scan_on_push missing.
# Rule: SEC-AWS-ECR-001 (fix_disruption: none).
resource "aws_ecr_repository" "app" {
  name = "tf-analyze-bot-demo-app"
}

# Seed bug #2 — no lifecycle policy paired with the repository.
# Rule: SEC-AWS-ECR-002 (fix_disruption: none).
# (The bot will append an aws_ecr_lifecycle_policy resource.)

# Seed bug #3 — log group has no kms_key_id, so CloudWatch encrypts with
# an AWS-managed key instead of a customer-managed CMK.
# Rule: SEC-AWS-CWL-001 (fix_disruption: none).
resource "aws_cloudwatch_log_group" "app" {
  name              = "/tf-analyze-bot-demo/app"
  retention_in_days = 30
}

# Seed bug #4 — CloudFront serves plain HTTP via viewer_protocol_policy.
# Rule: SEC-AWS-CLOUDFRONT-001 (fix_disruption: none).
resource "aws_cloudfront_distribution" "cdn" {
  enabled = true

  origin {
    domain_name = "example.com"
    origin_id   = "primary"
  }

  default_cache_behavior {
    target_origin_id       = "primary"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Seed bug #5 — bucket exists but no paired aws_s3_bucket_public_access_block.
# Rule: SEC-AWS-S3-PUBLIC-BLOCK-001 (fix_disruption: none).
resource "aws_s3_bucket" "artifacts" {
  bucket = "tf-analyze-bot-demo-artifacts"
}
