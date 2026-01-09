#!/bin/bash
set -e

# Arguments
ENV=${1:-pr}
TFVARS_FILE="terraform/env/${ENV}.tfvars"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Determine Project Name
if [ -f "$TFVARS_FILE" ]; then
    # Extract project_name="value" -> value
    PROJECT=$(grep 'project_name' "$TFVARS_FILE" | awk -F'=' '{print $2}' | tr -d '" ')
else
    PROJECT="cmmxna"
fi

PROJECT_NAME="${PROJECT:-cmmxna}"
ENVIRONMENT="${ENV}"
PREFIX="/aws/lambda/${PROJECT_NAME}-${ENVIRONMENT}-"

echo "----------------------------------------------------------------"
echo "Cleaning CloudWatch Log Groups"
echo "----------------------------------------------------------------"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region:      $AWS_REGION"
echo "Prefix:      $PREFIX"
echo "----------------------------------------------------------------"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI not found on PATH"
    exit 1
fi

# Check Credentials (simple check)
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: Unable to authenticate with AWS. Check your .env or credentials."
    exit 1
fi

# List Log Groups
echo "Searching for log groups..."
GROUPS=$(aws logs describe-log-groups \
    --log-group-name-prefix "$PREFIX" \
    --region "$AWS_REGION" \
    --query 'logGroups[*].logGroupName' \
    --output text)

if [ -z "$GROUPS" ] || [ "$GROUPS" == "None" ]; then
    echo "No matching log groups found."
    exit 0
fi

# Delete Log Groups
for group in $GROUPS; do
    echo "Deleting: $group"
    aws logs delete-log-group --log-group-name "$group" --region "$AWS_REGION"
done

echo "----------------------------------------------------------------"
echo "Cleanup Complete"
echo "----------------------------------------------------------------"
