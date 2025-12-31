resource "aws_dynamodb_table" "mna_context" {
  name           = "${var.project_name}-mna-context"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}
