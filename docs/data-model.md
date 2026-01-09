# **Normalized Relational Model** (modeled in DynamoDB).

This document describes the 3-table data model used to support the M&A Cloud Maturity Assessment application. The design focuses on normalization, efficient querying, and immutability for audit purposes.

### **The 3-Table Data Model**

#### **1. Table: `mna_context` (The Header)**

- **Purpose:** Stores the high-level Organization metadata.
- **Cardinality:** 1 Record per M&A Deal.

| Attribute      | Key Type      | Value Pattern             | Notes                                   |
| -------------- | ------------- | ------------------------- | --------------------------------------- |
| **PK**         | **Partition** | `ORG#<UUID>`              | The "Foreign Key" used by other tables. |
| `company_info` | Map           | `{name, industry}`        |                                         |
| `contacts`     | Map           | `{ciso, remediation}`     |                                         |
| `features`     | Map           | `{scoring_enabled: true}` |                                         |

#### **2. Table: `mna_paas_item` (The Inventory)**

- **Purpose:** Stores the specific cloud accounts and their specific Vault configurations.
- **Cardinality:** 1 Record per Cloud Account.
- **Key Design:** We use the Cloud ID as the PK for uniqueness, and a GSI to group them by Org.

| Attribute      | Key Type      | Value Pattern                          | Notes                                                       |
| -------------- | ------------- | -------------------------------------- | ----------------------------------------------------------- |
| **PK**         | **Partition** | `RESOURCE#<CloudID>`                   | e.g., `RESOURCE#aws:123456789`                              |
| **OrgFK**      | **GSI-PK**    | `ORG#<UUID>`                           | **The Join Key.** Allows "Select \* from PaaS where Org=X". |
| `provider`     | String        | `aws` / `azure`                        |                                                             |
| `vault_config` | Map           | `{mount: "mna/acme", path: "aws/123"}` | **Stored specifically for this account.**                   |

#### **3. Table: `mna_scoring` (The Immutable Log)**

- **Purpose:** A Time-Series append-only log of scores. No updates, only new inserts.
- **Cardinality:** Many records per Cloud Account (History).

| Attribute | Key Type      | Value Pattern                   | Notes                              |
| --------- | ------------- | ------------------------------- | ---------------------------------- |
| **PK**    | **Partition** | `RESOURCE#<CloudID>`            | Same PK as PaaS Item table.        |
| **SK**    | **Sort**      | `TIME#<ISO_TIMESTAMP>`          | Makes every scan unique/immutable. |
| `score`   | Map           | `{current: 3, target: 6}`       |                                    |
| `facts`   | Map           | `{logging: "centralized", ...}` |                                    |
| `gaps`    | List          | `[...]`                         |                                    |

---

### **Use Case 1: Onboarding (CRUD)**

You write **one** record to `mna_context` and **many** records to `mna_paas_item`.

**Python Logic:**

```python
def onboard_organization(org_data, account_list):
    # 1. Write the Header
    context_table.put_item(Item={
        'PK': f"ORG#{org_data['uuid']}",
        'company': org_data['info'],
        'contacts': org_data['contacts']
    })

    # 2. Write the Line Items (Batch Write)
    with paas_table.batch_writer() as batch:
        for acc in account_list:
            batch.put_item(Item={
                'PK': f"RESOURCE#{acc['provider']}:{acc['id']}",
                'OrgFK': f"ORG#{org_data['uuid']}",  # <--- The Foreign Key
                'provider': acc['provider'],
                'label': acc['label'],

                # Store the specific Vault path for this specific account here
                'vault_config': {
                    'mount': org_data['vault_mount'],
                    'path': f"{org_data['vault_root']}/{acc['provider']}/{acc['id']}"
                }
            })

```

---

### **Use Case 2: Scoring (Immutable Insert)**

The scoring function fetches the specific `mna_paas_item` to get the Vault path (to login to the cloud), runs the scan, and then inserts a new row into `mna_scoring`.

**Python Logic:**

```python
def run_score(resource_id):
    # 1. Get the Context/Config for this specific account
    # We fetch from PaaS Item table to get the Vault Path
    paas_record = paas_table.get_item(Key={'PK': f"RESOURCE#{resource_id}"})['Item']

    # 2. Authenticate & Run OPA (Abstracted)
    creds = vault.get_secret(paas_record['vault_config'])
    opa_result = run_assessment(creds)

    # 3. Insert Immutable Record (No Update!)
    scoring_table.put_item(Item={
        'PK': f"RESOURCE#{resource_id}",
        'SK': f"TIME#{datetime.utcnow().isoformat()}", # Unique Sort Key = New Row
        'OrgFK': paas_record['OrgFK'], # Carry forward the Org Link for reporting
        'score': opa_result['score'],
        'facts': opa_result['facts']
    })

```

---

### **Use Case 3: The "Completeness" Query**

To answer _"Have we scored everything?"_, you now query two tables and compare the counts.

1. **Query `mna_paas_item` (Index=`OrgFK`)**: "Give me the list of all accounts for Organization X."

- _Result:_ Set of 100 IDs.

2. **Query `mna_scoring` (Index=`OrgFK` or BatchGet)**: "Give me the latest score for these IDs."

- _Result:_ Set of 80 IDs.

3. **Math:** 100 - 80 = 20 Missing Accounts.

---

### **Terraform for the 3 Tables**

```hcl
# 1. Context Table
resource "aws_dynamodb_table" "mna_context" {
  name         = "mna_context"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"

  attribute {
    name = "PK"
    type = "S"
  }
}

# 2. PaaS Inventory Table
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
  name         = "mna_scoring"
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

```
