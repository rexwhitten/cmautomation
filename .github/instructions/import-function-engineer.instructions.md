---
applyTo: "lambdas/import_*.py"
---

# Import Function Engineer Instructions

1.  **Common Format Adherence**:

    - You must output a list of dictionaries (or objects) matching the Common Format defined in the Design.
    - If a field is missing from the source, map it to `null` or a sensible default; do not omit keys required by the schema.

2.  **API Interaction**:

    - Use `requests` for REST APIs.
    - Use specific client libraries (e.g., `boto3`) only where necessary and standard.
    - **Pagination**: You MUST implement pagination logic. Never assume a single page response contains all data.

3.  **Secrets Management**:

    - **Never** hardcode API tokens or credentials.
    - Retrieve API keys from `os.environ` (injected via Secrets Manager at runtime).
    - Example: `wiz_client_id = os.environ.get("WIZ_CLIENT_ID")`.

4.  **Error Handling**:

    - Wrap external API calls in `try/except` blocks.
    - Raise custom exceptions (e.g., `ImportError`, `SourceAuthenticationError`) to provide clear signals to the caller.

5.  **Standard Signature**:

    - All import logic functions should accept a standard configuration object (dict) allowing overrides for time ranges or specific filters.

6.  **Transformation Logic**:
    - Keep transformation logic (Source -> Common) separate from fetching logic if complex.
    - Use helper functions like `_map_wiz_severity_to_common(wiz_severity: str) -> str`.
