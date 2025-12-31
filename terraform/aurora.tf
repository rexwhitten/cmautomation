resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/database/password"
  description = "Master password for the Aurora database"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = {
    Project = var.project_name
  }
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/database/username"
  description = "Master username for the Aurora database"
  type        = "String"
  value       = var.db_username

  tags = {
    Project = var.project_name
  }
}

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/${var.project_name}/database/endpoint"
  description = "Endpoint for the Aurora database"
  type        = "String"
  value       = aws_rds_cluster.aurora.endpoint

  tags = {
    Project = var.project_name
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${var.project_name}-aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "15.4"
  database_name           = "cmmx_db"
  master_username         = var.db_username
  master_password         = random_password.db_password.result
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
  skip_final_snapshot     = true
  
  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = {
    Project = var.project_name
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.vpc_private_subnets

  tags = {
    Project = var.project_name
  }
}
