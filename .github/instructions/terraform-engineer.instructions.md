---
applyTo: "terraform/**/*.tf"
---

# Terraform Operational Rules

These rules apply to all Terraform files (`*.tf`) in the workspace.

## 1. Code Formatting & Style

- **Format**: All code must be formatted using `terraform fmt`.
- **Indentation**: Use 2 spaces for indentation.
- **Blocks**: Separate logical blocks (resources, variables) with a single empty line.

## 2. Variable Usage

- **Descriptions**: All `variable` blocks must include a `description`.
- **Types**: All `variable` blocks must include a `type` constraint (e.g., `type = string`, `type = list(string)`).
- **Defaults**: Provide `default` values only where sensible; prefer forcing users to provide values for critical parameters.

## 3. Resource Definition

- **Tags**: All resources that support tagging must include the standard tags defined in the design.
- **Hardcoding**: Avoid hardcoding values (IDs, ARNs). Use data sources or references to other resources.

## 4. Outputs

- **Sensitivity**: Outputs containing secrets (passwords, keys) must have `sensitive = true`.
- **Descriptions**: All `output` blocks should include a `description`.

## 5. Validation

- Before committing or applying, ensure:
  1.  `terraform fmt` has been run.
  2.  `terraform validate` passes.

## 6. Specific Resource Rules

- **IAM**:
  - Do not use `aws_iam_policy_attachment` (exclusive). Use `aws_iam_role_policy_attachment` or `aws_iam_user_policy_attachment`.
- **Security Groups**:
  - Descriptions are mandatory for all `ingress` and `egress` rules.
  - Avoid `0.0.0.0/0` for ingress unless it is a public web server (port 80/443).
