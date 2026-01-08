# OPA Python Engineer Design Manifesto

This document outlines the architectural standards for integrating Python applications with Open Policy Agent (OPA).

## I. Core Architectural Axioms

### 1. Decoupling Policy from Code

- **The Rule:** Business logic should not contain hardcoded authorization rules.
- **The "Why":** Hardcoded rules are difficult to update and audit. OPA allows policies to be managed separately.
- **Best Practice:**
  - The application acts as a Policy Enforcement Point (PEP).
  - OPA acts as the Policy Decision Point (PDP).
  - The application queries OPA and enforces the returned decision.

### 2. Fail-Closed Security

- **The Rule:** If OPA cannot be reached or returns an error, the default action must be to deny access.
- **The "Why":** Security failures should not result in unauthorized access.
- **Best Practice:**
  - Wrap OPA calls in try/except blocks.
  - In the `except` block, return a "deny" decision and log the error.

### 3. Structured Inputs

- **The Rule:** Inputs to OPA must be consistent and structured.
- **The "Why":** Policies rely on the structure of the input data. Inconsistent inputs lead to unpredictable policy behavior.
- **Best Practice:**
  - Define Pydantic models or TypedDicts for the `input` document sent to OPA.
  - Ensure the input includes all necessary context (user, resource, action, environment).

## II. Implementation Patterns

### The OPA Client Wrapper

- **Pattern:** Create a dedicated class or module for OPA interactions.
- **Responsibilities:**
  - Constructing the OPA URL.
  - Serializing the input.
  - Making the HTTP request.
  - Deserializing the result.
  - Handling errors.

### Context Injection

- **Pattern:** Inject the OPA client into services or handlers.
- **Benefit:** Facilitates testing (mocking the OPA client) and configuration management.

### Decision Caching (Optional)

- **Pattern:** Cache OPA decisions for a short duration if performance is critical.
- **Caveat:** Ensure cache invalidation or short TTLs to respect policy changes.
