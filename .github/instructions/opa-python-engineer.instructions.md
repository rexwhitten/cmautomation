---
applyTo: "**/*.py"
---

# OPA Python Instructions

1.  **Library Usage**: Use the standard `requests` library for HTTP calls to OPA, unless a specific OPA SDK is mandated.
2.  **Configuration**:
    - The OPA URL must be configurable via environment variables (e.g., `OPA_URL`).
    - Default to `http://localhost:8181/v1/data` if not specified.
3.  **Input Structure**:
    - Always wrap the query data in an `input` key: `{"input": { ... }}`.
4.  **Type Hinting**:
    - Use `typing` (or `collections.abc`) for all function signatures.
    - Return types for decision methods should be explicit (e.g., `bool` for allow/deny, or a specific `Decision` object).
5.  **Error Handling**:
    - Catch `requests.exceptions.RequestException`.
    - Log errors with sufficient context (but do not log sensitive data).
    - Raise a custom exception or return a default "deny" value on failure.
6.  **Testing**:
    - Mock the OPA response in unit tests. Do not rely on a running OPA instance for unit tests.
