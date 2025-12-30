# CMMX Cloud Security Posture Tool

![CI/CD Status](https://img.shields.io/badge/build-passing-brightgreen)
![Python](https://img.shields.io/badge/python-3.12-blue)
![Terraform](https://img.shields.io/badge/terraform-1.x-purple)
![AWS](https://img.shields.io/badge/cloud-AWS-orange)

## Project Overview

CMMX is a cloud security posture tool designed to import, analyze, and report on security data from various sources (AWS, Azure, Wiz, Katana, Coralogix). It utilizes a serverless architecture on AWS, leveraging Lambda functions for data processing and Aurora for storage.

This project is built using the **Recursive Artifact Framework**, employing specialized AI agents to maintain code quality, documentation, and infrastructure standards.

## Architecture

The solution is deployed on AWS and consists of the following components:

- **Compute**: AWS Lambda (Container Images)
- **Storage**: Amazon Aurora (PostgreSQL), Amazon S3
- **Networking**: VPC with Public/Private Subnets, ALB for frontend access
- **Infrastructure as Code**: Terraform
- **Containerization**: Docker

### Key Components

- `handlers.py`: Entry points for Lambda functions (Onboarding, Import, Remediation, Reporting).
- `terraform/`: Infrastructure definitions.
- `.github/agents/`: AI Agent definitions for the Recursive Artifact Framework.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Docker Desktop](https://www.docker.com/products/docker-desktop) (or Rancher Desktop)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.
- AWS Credentials configured locally or in your environment.

## Getting Started

1.  **Clone the repository**:

    ```bash
    git clone <repository-url>
    cd devcontainer-aws-python
    ```

2.  **Open in Dev Container**:
    Open the folder in VS Code. When prompted, click "Reopen in Container". This will set up your environment with all necessary tools (Python, Terraform, AWS CLI).

3.  **Configure Environment**:
    Create a `.env` file in the root directory (if not already present) to override default Makefile variables if needed.

## Usage

We use `make` to orchestrate common development tasks.

### Build and Test

- **Run Tests**:

  ```bash
  make test
  ```

  Runs `pytest` with coverage reports.

- **Build Docker Image**:

  ```bash
  make docker-build
  ```

  Builds the Lambda container image.

- **Push to ECR**:
  ```bash
  make docker-push
  ```
  Tags and pushes the image to Amazon ECR. _Note: Requires AWS credentials._

### Infrastructure Deployment

Infrastructure is managed via Terraform in the `terraform/` directory.

1.  **Initialize**:

    ```bash
    cd terraform
    terraform init
    ```

2.  **Plan**:

    ```bash
    terraform plan
    ```

3.  **Apply**:
    ```bash
    terraform apply
    ```

## Project Structure

```text
.
├── .devcontainer/      # Dev Container configuration
├── .github/            # Recursive Artifact Framework (Agents, Design, Instructions)
├── helpers/            # Utility scripts
├── terraform/          # Terraform infrastructure code
├── tests/              # Python tests
├── handlers.py         # Lambda function handlers
├── Makefile            # Build automation
├── README.md           # This file
└── requirements.txt    # Python dependencies
```

## Recursive Artifact Framework

This project uses a unique development framework where "Agents" are defined to handle specific domains.

- **Terraform Engineer**: Manages `terraform/`
- **Python Serverless Engineer**: Manages `handlers.py`
- **Python Test Engineer**: Manages `tests/`
- **README Maintainer**: Manages documentation

See [.github/agents](./.github/agents) for more details.

- **Python: Launch as Module**: Allows launching Python files as modules using the Command Variable extension.

## Useful Links

- Remote - Containers Extension
- Python Docker Image
- VS Code Python Extension

Feel free to explore and modify the setup to fit your development needs!
