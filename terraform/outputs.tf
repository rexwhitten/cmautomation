output "example_user_password_parameter_path" {
  description = "The SSM Parameter path containing the temporary password for the example user."
  value       = aws_ssm_parameter.example_user_password.name
}

# Lambda Function URLs - for frontend direct access
output "onboarding_url" {
  description = "HTTPS URL for the onboarding Lambda function"
  value       = one(aws_lambda_function_url.onboarding[*].function_url)
}

output "frontend_url" {
  description = "HTTPS URL for the frontend proxy Lambda function"
  value       = one(aws_lambda_function_url.frontend_proxy[*].function_url)
}

output "import_aws_url" {
  description = "HTTPS URL for the AWS import Lambda function"
  value       = one(aws_lambda_function_url.import_aws[*].function_url)
}

output "import_azure_url" {
  description = "HTTPS URL for the Azure import Lambda function"
  value       = one(aws_lambda_function_url.import_azure[*].function_url)
}

output "import_wiz_url" {
  description = "HTTPS URL for the Wiz import Lambda function"
  value       = one(aws_lambda_function_url.import_wiz[*].function_url)
}

output "import_katana_url" {
  description = "HTTPS URL for the Katana import Lambda function"
  value       = one(aws_lambda_function_url.import_katana[*].function_url)
}

output "import_coralogix_url" {
  description = "HTTPS URL for the Coralogix import Lambda function"
  value       = one(aws_lambda_function_url.import_coralogix[*].function_url)
}

output "scoring_url" {
  description = "HTTPS URL for the scoring Lambda function"
  value       = one(aws_lambda_function_url.scoring[*].function_url)
}

# CloudWatch Resources
output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch Dashboard for Lambda monitoring"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.lambda_dashboard.dashboard_name}"
}

output "cloudwatch_log_groups" {
  description = "CloudWatch Log Group names for all Lambda functions"
  value = {
    for key, lg in aws_cloudwatch_log_group.lambda_logs : key => lg.name
  }
}

