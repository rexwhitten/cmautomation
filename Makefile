# Makefile for Lambda Python Container

# if a local .env exists source it in, otherwise move on
# Load .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

SDLC_ENV ?= pr
ECR_REGION ?= us-east-1
AWS_ACCOUNT_ID ?= 704855531002
ECR_REPO ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(ECR_REGION).amazonaws.com/cmmx
IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")
IMAGE_NAME ?= $(ECR_REPO):$(IMAGE_TAG)

# terraform 
WORKSPACE_DIR := ./terraform

.PHONY: test build docker-build docker-push clean

test:
	pytest --maxfail=1 --disable-warnings -v tests/

build:
	pip install -r requirements.txt

# Build the Docker image
docker-build:
	docker build -t $(IMAGE_NAME) .

# Push the Docker image to ECR and publish the ARN to an AWS SSM Parameter
docker-push: docker-build
	@echo "Ensuring ECR repository exists..."
	set -a; [ -f $(CURDIR)/.env ] && . $(CURDIR)/.env; set +a; \
	REPO_NAME=$$(echo $(ECR_REPO) | rev | cut -d'/' -f1 | rev); \
	if command -v aws >/dev/null 2>&1; then \
		aws ecr describe-repositories --repository-names $$REPO_NAME --region $(ECR_REGION) > /dev/null 2>&1 || aws ecr create-repository --repository-name $$REPO_NAME --region $(ECR_REGION); \
		aws ecr get-login-password --region $(ECR_REGION) | docker login --username AWS --password-stdin $$(echo $(ECR_REPO) | cut -d'/' -f1); \
	else \
		docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION public.ecr.aws/aws-cli/aws-cli:latest ecr describe-repositories --repository-names $$REPO_NAME --region $(ECR_REGION) > /dev/null 2>&1 || \
		docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION public.ecr.aws/aws-cli/aws-cli:latest ecr create-repository --repository-name $$REPO_NAME --region $(ECR_REGION); \
		docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION public.ecr.aws/aws-cli/aws-cli:latest ecr get-login-password --region $(ECR_REGION) | docker login --username AWS --password-stdin $$(echo $(ECR_REPO) | cut -d'/' -f1); \
	fi
	docker push $(IMAGE_NAME)
	@echo "Publishing Image URI to SSM..."
	set -a; [ -f $(CURDIR)/.env ] && . $(CURDIR)/.env; set +a; \
	REPO_NAME=$$(echo $(ECR_REPO) | rev | cut -d'/' -f1 | rev); \
	if command -v aws >/dev/null 2>&1; then \
		aws ssm put-parameter --name "/app/$$REPO_NAME/image_uri" --value "$(IMAGE_NAME)" --type String --overwrite --region $(ECR_REGION); \
	else \
		docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION public.ecr.aws/aws-cli/aws-cli:latest ssm put-parameter --name "/app/$$REPO_NAME/image_uri" --value "$(IMAGE_NAME)" --type String --overwrite --region $(ECR_REGION); \
	fi
	




# Clean up Python cache files
clean:
	rm -rf __pycache__ .pytest_cache

# Terraform targets
init:
	@echo "Initializing Terraform in $(WORKSPACE_DIR) for environment $(SDLC_ENV)"
	@cd $(WORKSPACE_DIR) && \
		rm -rf .terraform && \
		rm -rf .terraform.lock.hcl && \
		terraform init \
			-backend-config="./env/$(SDLC_ENV).tfbackend" \
			-reconfigure \
			-upgrade

preplan:
	@echo "Validating Terraform configuration in $(WORKSPACE_DIR) for environment $(SDLC_ENV)"
	@cd $(WORKSPACE_DIR) && \
		terraform validate

plan:
	@echo "Planning Terraform changes in $(WORKSPACE_DIR) for environment $(SDLC_ENV)"
	@cd $(WORKSPACE_DIR) && \
		terraform plan \
			-var-file="./env/$(SDLC_ENV).tfvars" \
			-var="GIT_REPO=BSCA-ARC/arc-terraform"  \
			-var="GIT_HTTPS_REPO=$(TF_VAR_GIT_HTTPS_REPO)"  \
			-var="GIT_BRANCH=$(TF_VAR_GIT_BRANCH)" \
			-var="GIT_TOKEN=$(TF_VAR_GIT_TOKEN)"



apply:
	@cd $(WORKSPACE_DIR) && \
		terraform apply \
			-auto-approve \
			-var-file="./env/$(SDLC_ENV).tfvars" \
			-var="GIT_REPO=BSCA-ARC/arc-terraform"  \
			-var="GIT_HTTPS_REPO=$(TF_VAR_GIT_HTTPS_REPO)"  \
			-var="GIT_BRANCH=$(TF_VAR_GIT_BRANCH)" \
			-var="GIT_TOKEN=$(TF_VAR_GIT_TOKEN)"


tf/test:
	@cd $(WORKSPACE_DIR) && \
		terraform test \
			-var="SDLC_ENV=sandbox" \
			-var="GIT_REPO=$(TF_VAR_GIT_REPO)"  \
			-var="GIT_HTTPS_REPO=$(TF_VAR_GIT_HTTPS_REPO)"  \
			-var="GIT_BRANCH=$(TF_VAR_GIT_BRANCH)" \
			-var="GIT_TOKEN=$(TF_VAR_GIT_TOKEN)";