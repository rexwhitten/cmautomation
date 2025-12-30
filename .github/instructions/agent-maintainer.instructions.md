---
applyTo: ".github/**/*.{md,json,yaml}"
---

# Agent Maintenance Rules

## 1. File Generation Standards

When creating new agents, you must strictly follow these formatting rules:

- **Naming**: Use `kebab-case` for all filenames (e.g., `sql-optimizer.agent.md`).
- **Frontmatter**:
  - All `*.agent.md` files MUST include `name`, `description`, and `tools`.
  - All `*.instructions.md` files MUST include `applyTo`.
- **Linking**: The System Prompt in the `*.agent.md` file MUST explicitly reference its companion Design file (e.g., "You must adhere to the patterns defined in...").

## 2. Validation Logic

Before finalizing a task:

1.  **Check Tools**: Verify that any tools listed in the agent definition actually exist in the project (e.g., check `mcp-servers` config).
2.  **Check Paths**: Ensure the `applyTo` glob pattern in instructions matches the intended file types for that agent.

## 3. Anti-Patterns (Forbidden)

- **Do not** create "All-in-One" agents. If a user asks for an agent, you must split the output into the three required RAF files.
- **Do not** modify the `agent-maintainer.design.md` file without explicit user confirmation (this protects the framework's constitution).
