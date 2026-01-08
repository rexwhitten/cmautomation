# DynamoDB Engineering Design

This document serves as the **Source of Truth** for all DynamoDB related decisions.

## Architectural Axioms

1.  **On-Demand Scaling**:

    - Use `PAY_PER_REQUEST` billing mode by default to handle unpredictable workloads without capacity planning.

2.  **Key Structure**:

    - **Partition Keys**: Must be high-cardinality to ensure even data distribution ("hot partition" avoidance).
    - **Sort Keys**: Use for hierarchical data or enabling range queries.

3.  **Naming Conventions**:

    - Tables: `${var.project_name}-<logical-name>` (e.g., `myproject-users`).
    - Attributes: `snake_case` (e.g., `user_id`, `created_at`).

4.  **Encryption**:
    - Server-Side Encryption (SSE) must be enabled (usually default, but explicit `server_side_encryption` block in Terraform is good practice if using CMK).

## Access Patterns

- **Definition First**: Before creating a table or index, explicitly list the "Access Patterns" (queries) the application will perform.
- **Indexes**: Use Global Secondary Indexes (GSIs) sparingly to support secondary access patterns. Avoid Local Secondary Indexes (LSIs) unless strictly necessary due to resizing limitations.

## Data Consistency

- Prefer **Eventual Consistency** for reads to reduce costs and improve throughput.
- Use **Strong Consistency** only when business logic strictly mandates it.

## Terraform Integration

- DynamoDB resources should be defined in `terraform/dynamodb.tf` or valid module files.
- Tagging must follow the project standard (`Project`, `Environment`, `ManagedBy`).
