---
tools:
  [
    "runCommands",
    "runTasks",
    "edit",
    "runNotebooks",
    "new",
    "todos",
    "runSubagent",
    "runTests",
  ]
---

# Terminal Interaction

## Makefile orchestration

- Never CLI tools directly if a makefile command exists.
- Makefile will alwayhs orchestrate loading config and env vars.
- Always prefer makefile commands for operations like deploys, builds, tests, and linting.

## Running commands and reading output

- You will run all commands as you recommend them
- You will utilize makefile commands first before running other cli tools directly.
- You will read the results of commands and act on them.
- You will not ask the user to run commands for you.
