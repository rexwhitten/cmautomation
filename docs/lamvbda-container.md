# Spike Outcome: Single-Container Architecture for M&A Security Platform

---

## 1. Executive Summary

This spike investigated the feasibility and operational impact of packaging multiple Lambda functions (Scorer, Remediator, Onboarding) into a **single container image**.

**Conclusion:** We recommend adopting the **"One Image, Many Handlers"** pattern. This approach significantly simplifies our CI/CD pipeline and ensures code consistency across functions without introducing meaningful performance penalties for our specific low-concurrency use case.

## 2. The Problem

> This documentation only references two functions but the final solution will include many functions.

Our platform consists of distinct logical components (Scoring, Remediation, Onboarding) that share significant underlying logic (data models, utility libraries, and configuration parsing).

Maintaining separate Dockerfiles and build pipelines for each function results in:

- **Duplicate Logic:** Shared code must be copied or packaged into complex layers.
- **Slow CI/CD:** Building and pushing 3-4 distinct images per commit increases build time and storage costs.
- **Drift:** Risk of "Scorer" using a different version of the utility library than "Remediator."

## 3. The Solution: "Monolithic Image, Dynamic Entrypoints"

Instead of building `scorer:latest`, `remediator:latest`, etc., we build a single `ma-platform:latest` image.

When deploying the AWS Lambda resources, we configure each function to use the **same image URI** but override the **Command (CMD)** parameter to point to the specific handler method required for that role.

### 3.1. Technical Implementation

#### A. The File Structure

All source code resides in a single directory structure within the container.

```text
/var/task/
├── common/             # Shared libraries (Logging, DynamoDB wrappers)
├── policy/             # OPA/Rego policies (Shared by all)
├── src/
│   ├── scorer.py       # Handler for Scoring Logic
│   ├── remediator.py   # Handler for Remediation Logic
│   └── onboarding.py   # Handler for API Gateway/Onboarding
└── Dockerfile          # Single definition for the entire platform

```

#### B. The Dockerfile

We install all dependencies for _all_ functions in one pass. The `CMD` instruction in the Dockerfile serves only as a default; it will be overridden by Terraform.

```dockerfile
FROM public.ecr.aws/lambda/python:3.10

# 1. Install Global Dependencies (OPA, AWS SDK, etc.)
COPY requirements.txt .
RUN pip install -r requirements.txt

# 2. Install OPA Binary (Used by Scorer)
ADD https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static /usr/local/bin/opa
RUN chmod 755 /usr/local/bin/opa

# 3. Copy ALL source code
COPY common/ ./common/
COPY policy/ ./policy/
COPY src/ ./src/

# 4. Default Command (Optional, serves as a fallback)
CMD [ "src.onboarding.lambda_handler" ]

```

#### C. The Terraform Configuration (The Magic)

We reuse the same image URI but change the `image_config` block for each function resource.

```hcl
# The Shared Image Repository
resource "aws_ecr_repository" "platform_repo" {
  name = "ma-platform-monolith"
}

# Function 1: Scorer
resource "aws_lambda_function" "scorer" {
  function_name = "ma-scorer"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.platform_repo.repository_url}:latest"

  # OVERRIDE: Point to the Scorer logic
  image_config {
    command = ["src.scorer.lambda_handler"]
  }
}

# Function 2: Remediator
resource "aws_lambda_function" "remediator" {
  function_name = "ma-remediator"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.platform_repo.repository_url}:latest"

  # OVERRIDE: Point to the Remediator logic
  image_config {
    command = ["src.remediator.lambda_handler"]
  }
}

```

## 4. Pros & Cons Analysis

### Advantages (Why we are doing this)

1. **Atomic Deployments:** A single `docker push` updates the entire platform. There is zero risk that the "Scorer" is running v1.0 code while the "Remediator" is running v1.1.
2. **Simplified CI/CD:** Our GitHub Actions workflow builds **one** container. This cuts CI time by ~60% compared to building 3 separate images.
3. **Shared Cache:** Since all functions run on the same base image with the same Python requirements, Docker layer caching is maximized.
4. **Local Development:** Developers only need to spin up one container to test any function locally.

### Risks & Mitigations (What we must watch)

1. **Image Size:** Including dependencies for _all_ functions increases the total image size.

- _Mitigation:_ Our dependencies (Boto3, Requests, OPA) are lightweight. Total image size remains under 500MB, well within Lambda limits.

2. **Least Privilege Violation:** The code for "Remediation" exists inside the "Scorer" container, even if not executed.

- _Mitigation:_ Security is enforced at the **IAM Role** level, not the container level. The `ma-scorer` Lambda function will still have a restricted IAM role that cannot access the Remediation queues, regardless of what code sits on the disk.

3. **Cold Starts:** Larger images _can_ incur slightly longer initialization times.

- _Mitigation:_ AWS "Lazy Loading" for container images minimizes this impact. For an asynchronous M&A scoring process, an extra 500ms of cold start is irrelevant.

## 5. Deployment Strategy

To operationalize this, our `Makefile` will change from iterating over directories to a single build command:

**Old Way:**

```bash
docker build -t scorer src/scorer
docker build -t remediator src/remediator
# ... repeat for N functions

```

**New Way (Recommended):**

```bash
docker build -t ma-platform .
docker push ma-platform
aws lambda update-function-code --function-name ma-scorer ...
aws lambda update-function-code --function-name ma-remediator ...

```

## 6. Verdict

**Proceed with the Monolithic Container approach.**
The operational simplicity far outweighs the theoretical purity of separate containers for this specific application. It aligns perfectly with our goal of "Ruthless Automation" by reducing the moving parts in our deployment pipeline.
