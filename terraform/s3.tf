resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "${var.project_name}-${var.environment}-frontend-assets-${data.aws_caller_identity.current.account_id}"

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "frontend_versioning" {
  bucket = aws_s3_bucket.frontend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload frontend assets to S3
resource "aws_s3_object" "frontend_assets" {
  for_each = fileset("${path.module}/../frontend", "**/*")

  bucket = aws_s3_bucket.frontend_bucket.id
  key    = "frontend/${each.value}"
  source = "${path.module}/../frontend/${each.value}"
  etag   = filemd5("${path.module}/../frontend/${each.value}")

  content_type = lookup({
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "ts"   = "application/typescript"
    "map"  = "application/json"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# Generate config.js with backend URLs
resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "frontend/config.js"
  content      = <<EOF
window.config = {
  onboardingUrl: "${one(aws_lambda_function_url.onboarding[*].function_url)}"
};
EOF
  content_type = "application/javascript"
}
