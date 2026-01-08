# OPA Rule Writer Design Manifesto

This document outlines the architectural standards for writing Rego policies.

## I. Core Architectural Axioms

### 1. Deny by Default

- **The Rule:** Policies should explicitly allow actions. If no allow rule matches, the result should be deny.
- **The "Why":** This is the safest security posture. It prevents accidental access due to missing rules.
- **Best Practice:**
  - Start with `default allow = false`.
  - Define specific conditions under which `allow` becomes `true`.

### 2. Hierarchical Data Management

- **The Rule:** Use packages to organize policies logically (e.g., by service or resource).
- **The "Why":** Prevents naming collisions and makes the policy base easier to navigate.
- **Best Practice:**
  - Use `package <system>.<component>`.
  - Example: `package app.api.authz`.

### 3. Test-Driven Policy Development

- **The Rule:** Every policy must have accompanying unit tests.
- **The "Why":** Rego logic can be subtle. Tests ensure the policy behaves as expected and prevents regressions.
- **Best Practice:**
  - Create a `_test.rego` file for every `.rego` file.
  - Cover both positive (allow) and negative (deny) cases.

## II. Implementation Patterns

### Helper Rules

- **Pattern:** Extract complex logic into helper rules (functions).
- **Benefit:** Improves readability and reusability.
- **Example:** `is_admin { input.user.roles[_] == "admin" }`

### Data Separation

- **Pattern:** Keep static data (like role definitions) separate from logic if possible, or load it as `data`.
- **Benefit:** Allows updating data without changing the policy logic.

### Input Validation

- **Pattern:** Validate the presence of required input fields before evaluating logic.
- **Benefit:** Prevents runtime errors or unexpected behavior due to missing data.
