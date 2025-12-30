locals {
  lambda_image_uri = "${aws_ecr_repository.repo.repository_url}:${var.image_tag}"
  
  functions = {
    onboarding           = "handlers.onboarding_handler"
    import_aws           = "handlers.import_aws_handler"
    import_azure         = "handlers.import_azure_handler"
    import_wiz           = "handlers.import_wiz_handler"
    import_katana        = "handlers.import_katana_handler"
    import_coralogix     = "handlers.import_coralogix_handler"
    remediation_planning = "handlers.remediation_planning_handler"
    reporting            = "handlers.reporting_handler"
    frontend_proxy       = "handlers.frontend_proxy_handler" # Assuming you added this to handlers.py
  }
}

resource "aws_lambda_function" "functions" {
  for_each = local.functions

  function_name = "${var.project_name}-${each.key}"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = local.lambda_image_uri

  image_config {
    command = [each.value]
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      FRONTEND_BUCKET = aws_s3_bucket.frontend_bucket.id
      DB_HOST         = aws_rds_cluster.aurora.endpoint
      DB_NAME         = aws_rds_cluster.aurora.database_name
      DB_USER         = var.db_username
      DB_PASSWORD     = var.db_password
    }
  }

  timeout = 60

  tags = {
    Project = var.project_name
  }
}
