# Terraform Engineering Design

This document serves as the **Source of Truth** for all Terraform infrastructure decisions.

## Architectural Axioms

1.  **Modularity**:

    - Use modules for repeatable infrastructure patterns.
    - Keep the root module (`terraform/`) focused on composition, not resource definition, where possible.

2.  **State Management**:

    - Remote state must be stored in S3 with encryption enabled.
    - State locking must be implemented using DynamoDB.
    - _Note: For this specific project, local state is acceptable during initial development, but migration to remote state is a priority._

3.  **Naming Conventions**:

    - Resources: `snake_case` (e.g., `aws_s3_bucket.frontend_assets`).
    - Variables: `snake_case` with descriptive names (e.g., `db_instance_class`).
    - Outputs: `snake_case` describing the value (e.g., `alb_dns_name`).
    - Tags: Use standard tags (`Project`, `Environment`, `ManagedBy = "Terraform"`).

4.  **Security & Compliance**:
    - **Least Privilege**: IAM roles must be scoped to specific resources and actions. Avoid `*` in Resource fields unless absolutely necessary.
    - **Encryption**: All data at rest (S3, RDS, EBS) must be encrypted.
    - **Public Access**: Block public access to S3 buckets and RDS instances unless explicitly required (e.g., public website).

## Project Structure

```
terraform/
├── providers.tf      # Provider configurations
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── main.tf           # (Optional) Main entry point or module calls
├── backend.tf        # Backend configuration
├── *.tf              # Resource-specific files (vpc.tf, s3.tf, etc.)
└── modules/          # Local modules (if any)
```

## Inputs and Outputs

- All inputs and outputs are well-documented with descriptions.
- All inputs have relevant validation logic (multiple scenarios if needed).

### Common Inputs

- `enabled` (bool): Enable or disable the resource/module. If true, this module provisions resources; if false, it does nothing.
- `environment` (string): The deployment environment (e.g., `dev`, `staging`, `prod`).
- `project_name` (string): The name of the project for tagging and identification.
- `region` (string): AWS region for resource deployment.

### Common Outputs

- `enabled` (bool): Reflects whether the resource/module is enabled.
- `ssm_parameters` (map): Map of created SSM Parameter Store entries (if any).

## Resource Patterns

### Lambda Functions

- Use `aws_lambda_function` with `package_type = "Image"` for container-based Lambdas.
- Environment variables should be passed via `environment { variables = { ... } }`.

### Networking

- All VPC infrmation is looked up via variables.
- All Subnet infromation is looked up via variables.
