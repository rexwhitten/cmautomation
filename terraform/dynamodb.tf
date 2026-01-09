# =============================================================================
# TABLE 1: CMM_MNA_Context
# Purpose: The "Parent" table. Stores Entity metadata and Onboarding switches.
# =============================================================================
resource "aws_dynamodb_table" "mna_context" {
  name         = "${var.project_name}_mna_context"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"

  attribute {
    name = "PK"
    type = "S"
  }
}

# =============================================================================
# TABLE 1: CMM_MNA_PAAS_ITEM
# Purpose: The inventory of PaaS items associated with MNA_Context.
# =============================================================================
resource "aws_dynamodb_table" "mna_paas_item" {
  name         = "mna_paas_item"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "OrgFK"
    type = "S"
  }

  # GSI: Find all accounts for an Org
  global_secondary_index {
    name               = "OrgInventoryIndex"
    hash_key           = "OrgFK"
    projection_type    = "ALL"
  }
}

# 3. Scoring Table (Immutable History)
resource "aws_dynamodb_table" "mna_scoring" {
  name         = "${var.project_name}_mna_scoring"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }
  
  attribute {
    name = "OrgFK" # Optional: Allows you to query all scores for an Org
    type = "S"
  }

  # GSI: Org-level Reporting
  global_secondary_index {
    name               = "OrgScoreRollup"
    hash_key           = "OrgFK"
    range_key          = "SK"
    projection_type    = "INCLUDE"
    non_key_attributes = ["score", "facts"]
  }
}