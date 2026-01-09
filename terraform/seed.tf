# =============================================================================
# LEVEL 1: The "Wild West" Acquisition
# Context: Just acquired. No standards. Goal is simply to get visibility.
# =============================================================================
resource "aws_dynamodb_table_item" "context_l1_loans" {
  table_name = aws_dynamodb_table.mna_context.name
  hash_key   = aws_dynamodb_table.mna_context.hash_key

  item = jsonencode({
    "PK": {"S": "ORG#LEVEL1-0000-0001-0000-000000000001"},
    
    "company_info": {"M": {
      "name":        {"S": "QuickCash Loans (Legacy)"},
      "industry":    {"S": "Consumer Lending"},
      "description": {"S": "Recent acquisition. High risk. No logging standards."}
    }},
    
    "contacts": {"M": {
      "ciso":        {"S": "interim-ciso@fiserv.com"},
      "remediation": {"S": "mna-team-alpha@fiserv.com"}
    }},

    "features": {"M": {
      "scoring_enabled":        {"BOOL": true},
      "target_maturity_level":  {"N": "1"},  # Target: Just get Wiz installed
      "drift_alerting_enabled": {"BOOL": false} # Don't alert on noise yet
    }}
  })
}

# =============================================================================
# LEVEL 2: The "Local Compliance" Shop
# Context: Basic hygiene. Logging exists but is local. Scripts are manual.
# =============================================================================
resource "aws_dynamodb_table_item" "context_l2_ledger" {
  table_name = aws_dynamodb_table.mna_context.name
  hash_key   = aws_dynamodb_table.mna_context.hash_key

  item = jsonencode({
    "PK": {"S": "ORG#LEVEL2-0000-0002-0000-000000000002"},

    "company_info": {"M": {
      "name":        {"S": "Ledger Block Inc"},
      "industry":    {"S": "Crypto / Blockchain"},
      "description": {"S": "Remediation phase. Local logging enabled. Manual hardening."}
    }},

    "contacts": {"M": {
      "ciso":        {"S": "security@ledgerblock.io"},
      "remediation": {"S": "devops@ledgerblock.io"}
    }},

    "features": {"M": {
      "scoring_enabled":        {"BOOL": true},
      "target_maturity_level":  {"N": "2"},  # Target: Local Logging & Scripts
      "drift_alerting_enabled": {"BOOL": true}
    }}
  })
}

# =============================================================================
# LEVEL 3: The "Enterprise Alignment" Firm
# Context: Day 0 Integration. Policies are switching to Enterprise management.
# =============================================================================
resource "aws_dynamodb_table_item" "context_l3_wealth" {
  table_name = aws_dynamodb_table.mna_context.name
  hash_key   = aws_dynamodb_table.mna_context.hash_key

  item = jsonencode({
    "PK": {"S": "ORG#LEVEL3-0000-0003-0000-000000000003"},

    "company_info": {"M": {
      "name":        {"S": "WealthSafe Advisors"},
      "industry":    {"S": "Wealth Management"},
      "description": {"S": "Pre-Merger Close. Enterprise Policy & FinOps integration."}
    }},

    "contacts": {"M": {
      "ciso":        {"S": "risk-officer@wealthsafe.com"},
      "remediation": {"S": "cloud-arch@fiserv-corp.com"}
    }},

    "features": {"M": {
      "scoring_enabled":        {"BOOL": true},
      "target_maturity_level":  {"N": "3"},  # Target: Enterprise Policy
      "drift_alerting_enabled": {"BOOL": true}
    }}
  })
}

# =============================================================================
# LEVEL 4: The "Network Integrated" Processor
# Context: Post-Merger (Day 1). Transit Gateway connected. High traffic flow.
# =============================================================================
resource "aws_dynamodb_table_item" "context_l4_payments" {
  table_name = aws_dynamodb_table.mna_context.name
  hash_key   = aws_dynamodb_table.mna_context.hash_key

  item = jsonencode({
    "PK": {"S": "ORG#LEVEL4-0000-0004-0000-000000000004"},

    "company_info": {"M": {
      "name":        {"S": "Global Pay Rails"},
      "industry":    {"S": "Payment Processing"},
      "description": {"S": "Connected to Transit Gateway. Production Traffic Live."}
    }},

    "contacts": {"M": {
      "ciso":        {"S": "ciso@globalpay.com"},
      "remediation": {"S": "noc@fiserv-commercial.com"}
    }},

    "features": {"M": {
      "scoring_enabled":        {"BOOL": true},
      "target_maturity_level":  {"N": "4"},  # Target: Network Integration
      "drift_alerting_enabled": {"BOOL": true}
    }}
  })
}

# =============================================================================
# LEVEL 5: The "Fortress" (End State)
# Context: Service Restrictions Active. Immutable Infrastructure.
# =============================================================================
resource "aws_dynamodb_table_item" "context_l5_surety" {
  table_name = aws_dynamodb_table.mna_context.name
  hash_key   = aws_dynamodb_table.mna_context.hash_key

  item = jsonencode({
    "PK": {"S": "ORG#LEVEL5-0000-0005-0000-000000000005"},

    "company_info": {"M": {
      "name":        {"S": "Surety Insurance Group"},
      "industry":    {"S": "InsurTech"},
      "description": {"S": "End State. Service Control Policies blocking unauthorized services."}
    }},

    "contacts": {"M": {
      "ciso":        {"S": "security@surety.com"},
      "remediation": {"S": "sre-team@surety.com"}
    }},

    "features": {"M": {
      "scoring_enabled":        {"BOOL": true},
      "target_maturity_level":  {"N": "5"},  # Target: Service Restriction / Parity
      "drift_alerting_enabled": {"BOOL": true}
    }}
  })
}