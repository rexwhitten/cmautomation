import pytest
from unittest.mock import MagicMock, patch
import json
import os
import sys
from importlib import reload


# Helper to ensure we start with a fresh module for top-level code execution
def clean_imports():
    if "lambdas.scoring" in sys.modules:
        del sys.modules["lambdas.scoring"]


@patch.dict(os.environ, {"CCM_MNA_ASSESSMENT_TABLE": "TestAssessmentsTable"})
@patch("boto3.client")
@patch("boto3.resource")
def test_scoring_logic_success(mock_boto_resource, mock_boto_client):
    clean_imports()

    # Setup mocks
    mock_s3 = MagicMock()
    mock_boto_client.return_value = mock_s3

    mock_dynamodb = MagicMock()
    mock_table = MagicMock()
    mock_boto_resource.return_value = mock_dynamodb
    mock_dynamodb.Table.return_value = mock_table

    # Mock S3 response
    finding_data = [
        {"resource_id": "res-123", "score": 100, "details": {"severity": "high"}}
    ]
    mock_body = MagicMock()
    mock_body.read.return_value = json.dumps(finding_data).encode("utf-8")
    mock_s3.get_object.return_value = {"Body": mock_body}

    # Import after mocks are set up
    from lambdas.scoring import scoring_logic

    # Create event
    event = {
        "Records": [
            {
                "eventSource": "aws:s3",
                "s3": {
                    "bucket": {"name": "test-bucket"},
                    "object": {"key": "findings.json"},
                },
            }
        ]
    }

    # Execute
    response = scoring_logic(event, {})

    # Verify response
    assert response["statusCode"] == 200
    response_body = json.loads(response["body"])
    assert response_body["processed_records"] == 1

    # Verify S3 Interaction
    mock_s3.get_object.assert_called_with(Bucket="test-bucket", Key="findings.json")

    # Verify DynamoDB Interaction
    mock_table.put_item.assert_called()
    call_args = mock_table.put_item.call_args[1]["Item"]
    assert call_args["PK"] == "RESOURCE#res-123"
    assert call_args["score"] == 100


@patch.dict(os.environ, {}, clear=True)  # Ensure var is unset
@patch("boto3.client")
@patch("boto3.resource")
def test_scoring_logic_missing_config(mock_boto_resource, mock_boto_client):
    clean_imports()

    # Import
    from lambdas.scoring import scoring_logic

    event = {}
    response = scoring_logic(event, {})

    assert response["statusCode"] == 500
    assert "Configuration error" in response["body"]


@patch.dict(os.environ, {"CCM_MNA_ASSESSMENT_TABLE": "TestAssessmentsTable"})
@patch("boto3.client")
@patch("boto3.resource")
def test_scoring_logic_s3_error(mock_boto_resource, mock_boto_client):
    clean_imports()

    # Setup mocks
    mock_s3 = MagicMock()
    mock_boto_client.return_value = mock_s3
    # Make S3 throw an error
    mock_s3.get_object.side_effect = Exception("S3 Access Denied")

    # Mock DynamoDB just to allow import to proceed
    mock_dynamodb = MagicMock()
    mock_boto_resource.return_value = mock_dynamodb

    from lambdas.scoring import scoring_logic

    event = {
        "Records": [
            {
                "eventSource": "aws:s3",
                "s3": {
                    "bucket": {"name": "test-bucket"},
                    "object": {"key": "bad-file.json"},
                },
            }
        ]
    }

    response = scoring_logic(event, {})

    # Should succeed with 0 processed records because it swallows the error per current implementation
    assert response["statusCode"] == 200
    response_body = json.loads(response["body"])
    assert response_body["processed_records"] == 0
