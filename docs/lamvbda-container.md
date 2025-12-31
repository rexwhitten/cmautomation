### Spike Artifact: Architectural Decision - Packaging Strategy

---

### 1. The Decision

We will package our entire application (Scorer, Remediator, Onboarding) as a **single Container Image** and deploy it to AWS Lambda.

### 2. The Rationale (The "Why")

While Lambda Layers are popular for sharing small Python libraries (like `requests`), they break down at the scale and complexity of our platform.

#### A. The "OPA Binary" Problem

Our platform relies on the Open Policy Agent (OPA) binary (`opa_linux_amd64`) to execute policy.

- **With Layers:** You must manually download the binary, zip it into a specific structure (`/bin/opa`), upload it as a layer, and ensure every function mounts it to `/opt/bin`. Local testing requires manually mocking this `/opt` path.

- **With Containers:** You add **one line** to your Dockerfile:
  `ADD https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static /usr/local/bin/opa`
  It works in production. It works on your laptop. It works in CI.

#### B. The "Shared Code" Problem

Our functions share significant logic (`common/dynamo.py`, `common/logger.py`).

- **With Layers:** Sharing code requires building a complex CI/CD pipeline that zips the `common/` folder, publishes it as a Layer Version, and updates the Lambda functions to point to the new Layer ARN. This introduces "Dependency Drift" (e.g., Scorer is on v2 of the Layer, Remediator is on v1).

- **With Containers:** We copy the code once during the build: `COPY common/ ./common/`. Every function is guaranteed to run the exact same version of the shared utilities.

#### C. Local Development Experience

- **With Layers:** Developers must install `sam-cli` or manually unzip layers to `/opt` to simulate the environment.
- **With Containers:** `docker run -p 9000:8080 my-image`. If it runs in Docker, it runs in Lambda.

---

### 3. Comparison Matrix

| Feature              | **Container Image (Selected)**                                 | **Zip + Layers (Rejected)**                                             |
| -------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------- |
| **Dependency Limit** | **10 GB** (Plenty for OPA + Python + WASM)                     | **250 MB** (Hard limit for Unzipped code + Layers)                      |
| **Shared Code**      | **Atomic.** Code is copied at build time. No version mismatch. | **Fragmented.** Layers are versioned independently. High risk of drift. |
| **Binary Binaries**  | **Native.** `ADD /usr/bin/tool`.                               | **Hack.** Must place in specific zip paths and mess with `$PATH`.       |
| **Local Testing**    | **Standard.** `docker run`.                                    | **Complex.** Requires SAM CLI or mocking.                               |
| **Build Tooling**    | **Simple.** Standard Dockerfile.                               | **Complex.** Custom scripts to zip folders and publish Layer Versions.  |

---

### 4. Implementation Details

#### A. The "Monolithic" Dockerfile

This single file builds the entire platform. Notice we install dependencies _once_ for all functions.

```dockerfile
# Use the AWS Lambda Python Base Image
FROM public.ecr.aws/lambda/python:3.10

# 1. INSTALL SYSTEM DEPENDENCIES (The OPA Binary)
# This is where Layers struggle. In Docker, it's one line.
ADD https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static /usr/local/bin/opa
RUN chmod 755 /usr/local/bin/opa

# 2. INSTALL PYTHON DEPENDENCIES
# We copy strict requirements first to leverage Docker Layer Caching
COPY requirements.txt .
RUN pip install -r requirements.txt

# 3. COPY SOURCE CODE (The Monolith)
# We copy everything. The handler decides what runs.
COPY common/ ./common/
COPY src/ ./src/

# 4. DEFAULT CMD (Can be overridden)
CMD [ "src.onboarding.lambda_handler" ]

```

#### B. The Terraform (One Image, Many Handlers)

We push **one image** to ECR. We deploy **three functions** pointing to that same image, but we override the `command` (Handler) for each.

```hcl
# 1. The Shared Image Repository
data "aws_ecr_repository" "monolith" {
  name = "ma-platform-monolith"
}

# --- FUNCTION 1: SCORER ---
resource "aws_lambda_function" "scorer" {
  function_name = "ma-scorer"
  role          = aws_iam_role.scorer_role.arn
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.monolith.repository_url}:latest"

  # OVERRIDE: This function behaves as the Scorer
  image_config {
    command = ["src.scorer.lambda_handler"]
  }
}

# --- FUNCTION 2: REMEDIATOR ---
resource "aws_lambda_function" "remediator" {
  function_name = "ma-remediator"
  role          = aws_iam_role.remediator_role.arn
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.monolith.repository_url}:latest"

  # OVERRIDE: This function behaves as the Remediator
  image_config {
    command = ["src.remediator.lambda_handler"]
  }
}

# --- FUNCTION 3: ONBOARDING ---
resource "aws_lambda_function" "onboarding" {
  function_name = "ma-onboarding"
  role          = aws_iam_role.onboarding_role.arn
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.monolith.repository_url}:latest"

  # OVERRIDE: This function behaves as the Onboarding API
  image_config {
    command = ["src.onboarding.lambda_handler"]
  }
}

```

### 5. Final Verdict

Using Layers would force us to build a complex "Layer Management" pipeline to handle the OPA binary and shared Python code.

By using **Containerized Lambda**, we collapse the build process into a single `docker build` command. The slight increase in image size (storage) is negligible compared to the massive reduction in operational complexity.
