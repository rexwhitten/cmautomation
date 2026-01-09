#!/bin/bash
set -euo pipefail

# Command is the first argument
COMMAND="${1:-default}"

# use default values unless specified from the command line
SDLC_ENV="${SDLC_ENV:-dev}"
IS_PIPELINE="${IS_PIPELINE:-false}"

# GIT
WORKSPACE_DIR="./terraform"
TF_VAR_GIT_HTTPS_REPO=$(git config --get remote.origin.url | sed 's/ssh:\/\/git@/https:\/\//;s/git@/https:\/\//;s/:/\//')
TF_VAR_GIT_REPO=$(git config --get remote.origin.url)
TF_VAR_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
TF_VAR_GIT_TOKEN="${GITHUB_TOKEN:-}"

# AWS 
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-704855531002}"

# ECR and Docker Image
ECR_REGION="${ECR_REGION:-us-east-1}"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${ECR_REGION}.amazonaws.com/cmmx"
IMAGE_TAG="$(git rev-parse --short HEAD 2>/dev/null || echo "latest")"
IMAGE_NAME="${ECR_REPO}:${IMAGE_TAG}"


test() {
    pytest --maxfail=1 --disable-warnings -v tests/
}

build(){
    pip install -r requirements.txt
}

docker_build(){
    docker build -t "${IMAGE_NAME}" .
}

docker_push(){
    # Build first
    docker_build

    echo "Ensuring ECR repository exists..."
    mkdir -p "${PWD}/tmp/docker-config"
    
    # Load .env if it exists
    if [ -f "${PWD}/.env" ]; then
        set -a
        source "${PWD}/.env"
        set +a
    fi

    export DOCKER_CONFIG="${PWD}/tmp/docker-config"
    
    # Extract repo name
    local repo_name
    repo_name=$(echo "${ECR_REPO}" | rev | cut -d'/' -f1 | rev)
    
    if command -v aws >/dev/null 2>&1; then
        aws ecr describe-repositories --repository-names "${repo_name}" --region "${ECR_REGION}" > /dev/null 2>&1 || \
            aws ecr create-repository --repository-name "${repo_name}" --region "${ECR_REGION}"
            
        aws ecr get-login-password --region "${ECR_REGION}" | \
            docker login --username AWS --password-stdin "$(echo "${ECR_REPO}" | cut -d'/' -f1)"
    else
        # Use docker container for AWS CLI if not installed locally
        docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
            public.ecr.aws/aws-cli/aws-cli:latest ecr describe-repositories --repository-names "${repo_name}" --region "${ECR_REGION}" > /dev/null 2>&1 || \
        docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
            public.ecr.aws/aws-cli/aws-cli:latest ecr create-repository --repository-name "${repo_name}" --region "${ECR_REGION}"
            
        docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
            public.ecr.aws/aws-cli/aws-cli:latest ecr get-login-password --region "${ECR_REGION}" | \
            docker login --username AWS --password-stdin "$(echo "${ECR_REPO}" | cut -d'/' -f1)"
    fi

    docker push "${IMAGE_NAME}"
    
    echo "Publishing Image URI to SSM..."
    
    # The .env sourcing is redundant here as variables are already exported or set, but keeping for consistency if called standalone
    # (Though in a function scope, variables persist)
    
    if command -v aws >/dev/null 2>&1; then
        aws ssm put-parameter --name "/app/${repo_name}/image_uri" --value "${IMAGE_NAME}" --type String --overwrite --region "${ECR_REGION}"
    else
        docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
            public.ecr.aws/aws-cli/aws-cli:latest ssm put-parameter --name "/app/${repo_name}/image_uri" --value "${IMAGE_NAME}" --type String --overwrite --region "${ECR_REGION}"
    fi
}

clean(){
    rm -rf __pycache__ .pytest_cache
}

init(){
    echo "Initializing Terraform in ${WORKSPACE_DIR} for environment ${SDLC_ENV}"
    cd {{WORKSPACE_DIR}} && \
        rm -rf .terraform && \
        rm -rf .terraform.lock.hcl && \
        terraform init \
            -backend-config="./env/{{SDLC_ENV}}.tfbackend" \
            -reconfigure \
            -upgrade
}

default(){
    # echo out all the variables
    echo "SDLC_ENV: ${SDLC_ENV}"
    echo "IS_PIPELINE: ${IS_PIPELINE}"
    echo "WORKSPACE_DIR: ${WORKSPACE_DIR}"
    echo "TF_VAR_GIT_HTTPS_REPO: ${TF_VAR_GIT_HTTPS_REPO}"
    echo "TF_VAR_GIT_REPO: ${TF_VAR_GIT_REPO}"
    echo "TF_VAR_GIT_BRANCH: ${TF_VAR_GIT_BRANCH}"
    echo "AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
}

main(){
    # Check if the command exists as a function
    if declare -f "$COMMAND" > /dev/null; then
        # Run the command
        "$COMMAND"
    else
        # run default if no command found
        echo "Command '$COMMAND' not found. Running default."
        default
    fi
}

main "$@"