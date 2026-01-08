resource "aws_cognito_user_pool" "pool" {
  name = "${var.project_name}-user-pool"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  tags = local.tags
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${var.project_name}-client"

  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret     = true
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  
  # For ALB Auth, these call back to the ALB
  callback_urls = ["https://${aws_lb.alb.dns_name}/oauth2/idpresponse"]
  logout_urls   = ["https://${aws_lb.alb.dns_name}"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO"]
}

resource "random_id" "domain_suffix" {
  byte_length = 4
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "${var.project_name}-${random_id.domain_suffix.hex}"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "random_password" "example_user_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()_+"
  min_special      = 1
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

resource "aws_ssm_parameter" "example_user_password" {
  name        = "/${var.project_name}/${var.environment}/cognito/example-user/password"
  description = "Temporary password for example-user"
  type        = "SecureString"
  value       = random_password.example_user_password.result
  tags        = local.tags
}

resource "aws_cognito_user" "example" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "example-user"
  password     = random_password.example_user_password.result

  attributes = {
    email          = "example@internal.example.com"
    email_verified = "true"
  }
}

