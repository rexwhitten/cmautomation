output "example_user_password_parameter_path" {
  description = "The SSM Parameter path containing the temporary password for the example user."
  value       = aws_ssm_parameter.example_user_password.name
}
