---
applyTo: "**/*.rego"
---

# OPA Rule Writer Instructions

1.  **File Naming**:
    - Policy files: `*.rego` (e.g., `authz.rego`).
    - Test files: `*_test.rego` (e.g., `authz_test.rego`).
2.  **Formatting**:
    - All Rego code must be formatted using `opa fmt`.
3.  **Package Naming**:
    - Use lowercase, dot-separated package names.
    - Example: `package main`, `package http.authz`.
4.  **Comments**:
    - Add comments to explain complex rules.
    - Use the `metadoc` standard if applicable for documentation generation.
5.  **Testing**:
    - Test rules should be prefixed with `test_`.
    - Use `with input as ...` to mock inputs in tests.
    - Use `with data as ...` to mock external data.
6.  **Performance**:
    - Avoid iteration over large collections if possible.
    - Use sets for membership checks (`x in set`).
