# Import Function Engineer Design Manifesto

This document outlines the architectural standards for security data ingestion and the implementation of the Common Finding Format.

## I. Core Architectural Axioms

### 1. The Canonical Schema Rule

- **The Rule:** Every import function _must_ return data in the strict **Common Finding Format**.
- **The "Why":** Downstream systems (Remediation, Reporting) cannot handle N different schemas from N vendors. They expect one.
- **Best Practice:**
  - Define a shared Pydantic model (e.g., `CommonFinding`) in a shared module.
  - Map fields explicitly: `source_severity="High"` -> `common_severity="CRITICAL"`.

### 2. The Anti-Corruption Layer

- **The Rule:** Never leak vendor-specific implementation details into the common model keys.
- **The "Why":** If we switch from Wiz to another tool, the valid keys in our database should not change.
- **Best Practice:**
  - Store the full raw JSON payload in a dedicated `raw_data` field within the common format, but do not promote random vendor keys to top-level fields.

### 3. Stateless Ingestion

- **The Rule:** Import functions usually run as Lambdas and must be stateless.
- **The "Why":** Large imports might timeout.
- **Best Practice:**
  - If an import is massive, design for continuation tokens or split the work (though simple imports should just fetch-and-return).

## II. The Common Format Pattern

(Agent Implementation Note: You enforce this structure)

```json
{
  "id": "uuid-v4",
  "source_system": "wiz|aws|azure",
  "source_id": "original-vendor-id",
  "title": "S3 Bucket Open to Public",
  "description": "...",
  "severity": "LOW|MEDIUM|HIGH|CRITICAL",
  "resource_id": "arn:aws:s3:::my-bucket",
  "first_seen": "ISO8601-Timestamp",
  "last_seen": "ISO8601-Timestamp",
  "raw_data": { ... }
}
```

## III. Query Strategy

- **Targeted Fetching:** Do not "fetch all". Always implement filtering capabilities (e.g., "fetch only Criticals", "fetch since last run") to optimize API usage.
- **Graceful Degradation:** If a source API is flaky, the importer should retry with backoff, then fail cleanly without crashing the orchestration layer.
