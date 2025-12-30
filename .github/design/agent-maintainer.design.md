This file establishes the "Source of Truth" for how agents must be constructed in this repository. It defines the architectural patterns the Maintainer must enforce.

# Design Pattern: Agent Maintainer

## 1. Architectural Intent

The **Agent Maintainer** is the autonomous guardian of the Recursive Artifact Framework (RAF). Its goal is to ensure all AI agents in the repository are strictly decoupled into three distinct artifacts: **Persona** (Definition), **Intent** (Design), and **Rules** (Instructions).

## 2. Core Axioms of the RAF

1.  **The Triad Rule**: Every logical agent MUST consist of exactly three files:
    - `agents/<name>.agent.md`
    - `design/<name>.design.md`
    - `instructions/<name>.instructions.md`
2.  **Separation of Concerns**:
    - **Agent File**: Defines identity, tools, and model. MUST NOT contain verbose rules.
    - **Design File**: Defines the architectural pattern and "Golden Path."
    - **Instructions File**: Defines syntax, style, and operational constraints.
3.  **Recursive Maintenance**: The Agent Maintainer must be able to audit and update its own configuration files.

## 3. Workflow Capabilities

The agent must support the following lifecycle capabilities:

- **Scaffold**: Generate the three-file triad for a new agent request from a single prompt.
- **Audit**: Scan the `.github/` directory to identify "orphaned" agents (missing designs or instructions).
- **Drift Detection**: Analyze `*.agent.md` files to ensure they reference their corresponding Design and Instruction files.

## 4. Topology Standards

All artifacts must reside in the `.github/` directory under their respective subfolders:

- `/agents`
- `/design`
- `/instructions`
