locals {
  functions = {
    onboarding           = "handlers.onboarding_handler"
    import_aws           = "handlers.import_aws_handler"
    import_azure         = "handlers.import_azure_handler"
    import_wiz           = "handlers.import_wiz_handler"
    import_katana        = "handlers.import_katana_handler"
    import_coralogix     = "handlers.import_coralogix_handler"
    remediation_planning = "handlers.remediation_planning_handler"
    reporting            = "handlers.reporting_handler"
    scoring              = "handlers.scoring_handler"
    frontend_proxy       = "handlers.frontend_handler"
  }
}

resource "aws_security_group" "functions" {
  name        = "${var.project_name}-${var.environment}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "functions" {
  for_each      = local.functions
  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = data.aws_ssm_parameter.image_uri[0].value

  image_config {
    command = [each.value]
  }

  vpc_config {
    subnet_ids         = toset(aws_subnet.private[*].id)
    security_group_ids = [aws_security_group.functions.id]
  }

  environment {
    variables = {
      CCM_MNA_FRONTEND_BUCKET             = aws_s3_bucket.frontend_bucket.id
      CCM_MNA_FRONTEND_BUCKET_KEY_PREFIX  = "frontend/"
      CCM_MNA_IMPORT_BUCKET               = aws_s3_bucket.frontend_bucket.id
      CCM_MNA_IMPORT_BUCKET_KEY_PREFIX    = "imports/"
      CCM_MNA_CONTEXT_TABLE               = aws_dynamodb_table.mna_context.name
      CCM_MNA_SCORING_TABLE               = aws_dynamodb_table.mna_scoring.name
      CCM_MNA_PAAS_ITEM_TABLE             = aws_dynamodb_table.mna_paas_item.name
    }
  }

  # 15 minute timeout
  timeout = 900
  tags = local.tags

  # Ensure CloudWatch log group is created first
  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}
