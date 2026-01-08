# Seed Data 

# =============================================================================
# SEED DATA 1: The Context (The M&A Entity)
# =============================================================================
resource "aws_dynamodb_table_item" "synthetic_context" {
  table_name = aws_dynamodb_table.context.name
  hash_key   = aws_dynamodb_table.context.hash_key
  range_key  = aws_dynamodb_table.context.range_key

  item = jsonencode({
    "PK": {"S": "ENTITY#SYNTHETIC_TEST_001"},
    "SK": {"S": "META#INFO"},
    
    # GSI for Resource Lookup: Linking AWS Account 999999999999 to this Entity
    "GSI1PK": {"S": "RESOURCE#aws:999999999999"},
    "GSI1SK": {"S": "LINK"},

    # Metadata Attributes
    "company_name":    {"S": "Acme Corp (Synthetic Test)"},
    "contact_email":   {"S": "admin@acme-test.com"},
    "is_scoring":      {"BOOL": true},
    "is_complete":     {"BOOL": false},
    "aws_account_ids": {"L": [{"S": "999999999999"}]},
    "azure_sub_ids":   {"L": []}
  })
}

# =============================================================================
# SEED DATA 2: The Assessment (The Scored Resource)
# =============================================================================
resource "aws_dynamodb_table_item" "synthetic_assessment" {
  table_name = aws_dynamodb_table.assessments.name
  hash_key   = aws_dynamodb_table.assessments.hash_key
  range_key  = aws_dynamodb_table.assessments.range_key

  item = jsonencode({
    "PK": {"S": "RESOURCE#aws:999999999999"},
    "SK": {"S": "STATE#LATEST"},

    # Link back to the Parent Entity
    "GSI1PK": {"S": "ENTITY#SYNTHETIC_TEST_001"},
    
    "scan_time":     {"S": "2023-10-27T10:00:00Z"},
    "resource_type": {"S": "AWS"},

    # --- ABSTRACT BLOCK 1: The Score ---
    "score": {"M": {
      "current": {"N": "3"},
      "target":  {"N": "6"},
      "label":   {"S": "COMPLIANT_L3"},
      "version": {"S": "1.0"}
    }},

    # --- ABSTRACT BLOCK 2: The Facts (Matches your Python Enums) ---
    "facts": {"M": {
      "environment":          {"S": "production"},
      "impl_owner":           {"S": "fiserv_corporate"},
      "strategic_go_forward": {"BOOL": true},
      
      "logging_status":       {"S": "centralized"},
      "os_hardening":         {"S": "hardening_scripts"},
      
      # Lists in DynamoDB JSON are verbose: {"L": [{"S": "val"}]}
      "agents":               {"L": [{"S": "crowdstrike"}]},
      "posture_tools":        {"L": [{"S": "wiz"}]},
      
      "network_connectivity": {"S": "non_transit"},
      "policy_enforcement":   {"S": "fiserv_enterprise"},
      "service_restriction":  {"S": "disabled"}
    }},

    # --- ABSTRACT BLOCK 3: The Gaps ---
    "gaps": {"L": [
      {"M": {
        "rule":        {"S": "NET-01"},
        "description": {"S": "Transit Connectivity Required for Level 4"}
      }}
    ]}
  })
}