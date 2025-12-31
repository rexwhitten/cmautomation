import pytest
from unittest.mock import MagicMock, patch
import json
import os


# Mock environment variables before importing the lambda
@patch.dict(os.environ, {"DYNAMODB_TABLE": "test-table"})
@patch("boto3.resource")
def test_onboarding_logic_list_records(mock_boto_resource):
    # Setup mock DynamoDB
    mock_table = MagicMock()
    mock_dynamodb = MagicMock()
    mock_boto_resource.return_value = mock_dynamodb
    mock_dynamodb.Table.return_value = mock_table

    # Mock scan response
    mock_table.scan.return_value = {"Items": []}

    # Import the module after mocking
    from lambdas.onboarding import onboarding_logic

    # Create a sample event for listing records
    event = {
        "httpMethod": "GET",
        "path": "/onboarding",
        "queryStringParameters": None,
        "body": None,
    }

    # Call the handler
    response = onboarding_logic(event, {})

    # Assertions
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["message"] == "Onboarding records retrieved successfully"
    assert body["data"] == []
