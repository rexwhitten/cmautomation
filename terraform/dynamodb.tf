# =============================================================================
# TABLE 1: CMM_MNA_Context
# Purpose: The "Parent" table. Stores Entity metadata and Onboarding switches.
# =============================================================================
resource "aws_dynamodb_table" "context" {
  name           = "CMM_MNA_Context"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  # 1. Primary Key Definition
  # PK Example: "ENTITY#550e8400-e29b"
  # SK Example: "META#INFO"
  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # 2. GSI Support Attributes
  # GSI1PK Example: "RESOURCE#aws:123456789" (Allows finding the Company via the AWS ID)
  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  # 3. Global Secondary Index: Resource Lookup
  # Access Pattern: "Who owns AWS Account 123?"
  global_secondary_index {
    name               = "ResourceLookupIndex"
    hash_key           = "GSI1PK"
    range_key          = "GSI1SK"
    projection_type    = "ALL" # Often needed for context lookups to get metadata quickly
  }

  # 4. Best Practices
  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(local.tags, {
    project     = var.project_name
    component   = "Context_Registry"
    description = "Stores MnA Entity metadata and scoring enablement flags"
  })
}

# =============================================================================
# TABLE 2: CMM_MNA_Assessments
# Purpose: The "Child" table. Stores generic 'facts', 'scores', and 'gaps'.
# =============================================================================
resource "aws_dynamodb_table" "assessments" {
  name           = "CMM_MNA_Assessments"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  # 1. Primary Key Definition
  # PK Example: "RESOURCE#aws:123456789"
  # SK Example: "STATE#LATEST" (Current) OR "STATE#2023-10-27T10:00:00" (History)
  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # 2. GSI Support Attributes
  # GSI1PK Example: "ENTITY#550e8400-e29b" (Links back to Context Table)
  attribute {
    name = "GSI1PK"
    type = "S"
  }
  
  # Note: GSI1SK isn't strictly defined as an attribute here because 
  # we reuse the main table's SK for the Index Range Key below.

  # 3. Global Secondary Index: Entity Rollup
  # Access Pattern: "Get me the scores for ALL accounts belonging to Acme Corp"
  global_secondary_index {
    name               = "EntityRollupIndex"
    hash_key           = "GSI1PK"
    range_key          = "SK"  # Reusing SK allows time-based queries on the GSI too
    projection_type    = "INCLUDE"
    non_key_attributes = ["score", "scan_time", "resource_type"]
  }

  # 4. Best Practices
  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(local.tags, {
    project     = var.project_name
    component   = "Assessment_Store"
    description = "Stores technical facts and scoring results"
  })
}