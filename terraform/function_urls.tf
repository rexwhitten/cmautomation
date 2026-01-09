# Lambda Function URLs - Direct HTTPS access to Lambda functions
# Allows frontend to POST directly without API Gateway

resource "aws_lambda_function_url" "onboarding" {
  count              = var.enable_function_urls ? 1 : 0
  function_name      = aws_lambda_function.functions["onboarding"].function_name
  authorization_type = "NONE" # Public access - consider using IAM or custom auth for production

  cors {
    allow_credentials = true
    allow_origins     = ["*"] # Restrict to your domain in production
    allow_methods     = ["GET", "POST", "PUT", "DELETE"]
    allow_headers     = ["*"]
    expose_headers    = ["*"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "frontend_proxy" {
  count              = var.enable_function_urls ? 1 : 0
  function_name      = aws_lambda_function.functions["frontend_proxy"].function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "import_aws" {
  count              = var.enable_function_urls ? 1 : 0
  function_name      = aws_lambda_function.functions["import_aws"].function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "import_azure" {
  count              = var.enable_function_urls ? 1 : 0
  function_name      = aws_lambda_function.functions["import_azure"].function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "import_wiz" {
  count              = var.enable_function_urls ? 1 : 0
  function_name      = aws_lambda_function.functions["import_wiz"].function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "import_katana" {
  count              = var.enable_function_urls ? 1 : 0
  function_name      = aws_lambda_function.functions["import_katana"].function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "import_coralogix" {
  count              = var.enable_function_urls ? 1 : 0
  function_name      = aws_lambda_function.functions["import_coralogix"].function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "scoring" {
  count              = var.enable_function_urls ? 1 : 0
  function_name      = aws_lambda_function.functions["scoring"].function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}
