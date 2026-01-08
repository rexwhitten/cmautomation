terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
     http = {
      source = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

variable "payload" { 
  type = string 
  default = "" 
}

variable "function_name" {}

resource "aws_lambda_invocation" "invoke" {
    function_name = var.function_name
    input         = var.payload
}

locals {
  result         = jsondecode(aws_lambda_invocation.invoke.result)
  status_code    = local.result.statusCode
  has_errors     = try(local.result.errors != null, false)
  error_messages = local.has_errors ? join(", ", local.result.errors) : ""
}

output "result" {
  value = aws_lambda_invocation.invoke.result
}

output "status_code" {
  value = local.status_code
}

output "has_errors" {
  value = local.has_errors
}

output "error_messages" {
  value = local.error_messages
}

output "is_not_implemented" {
  value = strcontains(lower(local.error_messages), "notimplementederror")
}