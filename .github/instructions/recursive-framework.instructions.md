Based on the **Recursive Artifact Framework** defined in the provided source material and the best practices for writing GitHub Copilot instructions, here is the instruction file configuration.

This file acts as the "constitution" for the framework, enforcing the separation of **Persona** (Agent), **Intent** (Design), and **Rules** (Instructions).

### Instruction File: `recursive-framework.instructions.md`

Save this file to `.github/instructions/recursive-framework.instructions.md`.

```markdown
---
applyTo: ".github/**/*"
---

# Recursive Artifact Framework Rules

## 1. Directory Topology & File Standards

You must strictly adhere to the following directory structure for all agentic workflows. Do not create agents outside of this topology.

- **Agents (`.github/agents/`)**:

  - Contains executable **Personas**.
  - **Rule**: Files must use the extension `*.agent.md`.
  - **Content**: Defines `name`, `description`, `tools`, and `model` in YAML frontmatter.

- **Design (`.github/design/`)**:

  - Contains the **Intent** and "Source of Truth".
  - **Rule**: Files must use the extension `*.design.md`.
  - **Content**: Defines architectural patterns, axioms, and templates that agents must implement.

- **Instructions (`.github/instructions/`)**:
  - Contains **Operational Rules**.
  - **Rule**: Files must use the extension `*.instructions.md`.
  - **Content**: Must include `applyTo` frontmatter to target specific file paths.

## 2. Decoupling Axioms

When creating or modifying agents, you must respect the separation of concerns:

1. **Persona ≠ Rules**: The `*.agent.md` file defines _who_ the agent is (identity and tools). It must **not** contain verbose coding standards; those belong in `*.instructions.md`.
2. **Persona ≠ Intent**: The `*.agent.md` file defines capabilities. It must refer to a `*.design.md` file for architectural decisions.

## 3. The Triad Pattern

Every agent implementation requires a linked triad of files. When asked to "scaffold a new agent," you must generate:

1. **The Definition**: `.github/agents/<name>.agent.md`
2. **The Design**: `.github/design/<name>.design.md`
3. **The Instructions**: `.github/instructions/<name>.instructions.md`

## 4. Cross-Referencing

- Agents must explicitly reference their design file in their system prompt (e.g., "You must adhere to the patterns defined in `.github/design/sql-architect.design.md`").
- Instruction files should link to relevant design documents for context.
```

### Framework Rationale & Source Context

- **Directory Structure**: The framework mandates specific folders (`agents`, `design`, `instructions`) to satisfy the axiom of separating definition from rules. This aligns with GitHub Copilot's requirement that agent definitions reside in `.github/agents` to be detected by the system.
- **Instruction Targeting**: The use of `applyTo: ".github/**/*"` ensures these rules are automatically loaded into context whenever a developer is working on the agent configuration itself, preventing architectural drift.
- **Separation of Concerns**: The framework explicitly moves "coding standards" out of the agent definition (which has a limited context window) and into `*.instructions.md` files, which Copilot automatically retrieves based on the active file context.
