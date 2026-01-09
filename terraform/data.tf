data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "image_uri" {
  count = var.enabled ? 1 : 0
  name  = "/app/cmmx/image_uri"
}

data "aws_availability_zones" "available" {
  state = "available"
}