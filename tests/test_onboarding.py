import pytest
from unittest.mock import MagicMock, patch
import json
import os
import sys


# Helper to ensure we start with a fresh module for top-level code execution
def clean_imports():
    if "lambdas.onboarding" in sys.modules:
        del sys.modules["lambdas.onboarding"]


@patch.dict(os.environ, {"CCM_MNA_CONTEXT_TABLE": "test-mna-context"})
@patch("boto3.resource")
def test_onboarding_logic_list_records(mock_boto_resource):
    clean_imports()

    # Setup mock DynamoDB
    mock_table = MagicMock()
    mock_dynamodb = MagicMock()
    mock_boto_resource.return_value = mock_dynamodb
    mock_dynamodb.Table.return_value = mock_table

    # Mock scan response
    mock_table.scan.return_value = {"Items": []}

    # Import the module after mocking
    from lambdas.onboarding import onboarding_logic

    # Accurate Test Event (adhere to this)
    event = {
        "version": "2.0",
        "routeKey": "$default",
        "rawPath": "/onboarding",
        "rawQueryString": "",
        "headers": {
            "sec-fetch-mode": "navigate",
            "x-amzn-tls-version": "TLSv1.3",
            "sec-fetch-site": "none",
            "x-forwarded-proto": "https",
            "accept-language": "en-US,en;q=0.9",
            "x-forwarded-port": "443",
            "x-forwarded-for": "108.80.167.251",
            "sec-fetch-user": "?1",
            "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "x-amzn-tls-cipher-suite": "TLS_AES_128_GCM_SHA256",
            "sec-ch-ua": '"Chromium";v="142", "Microsoft Edge";v="142", "Not_A Brand";v="99"',
            "x-amzn-trace-id": "Root=1-69603e48-39ad0c700f34176c7bcc0d70",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"Linux"',
            "host": "iajsfzbqza2r7vyggt5oi6puw40jdlhe.lambda-url.us-east-1.on.aws",
            "upgrade-insecure-requests": "1",
            "accept-encoding": "gzip, deflate, br, zstd",
            "user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0",
            "sec-fetch-dest": "document",
        },
        "requestContext": {
            "accountId": "anonymous",
            "apiId": "iajsfzbqza2r7vyggt5oi6puw40jdlhe",
            "domainName": "iajsfzbqza2r7vyggt5oi6puw40jdlhe.lambda-url.us-east-1.on.aws",
            "domainPrefix": "iajsfzbqza2r7vyggt5oi6puw40jdlhe",
            "http": {
                "method": "GET",
                "path": "/onboarding",
                "protocol": "HTTP/1.1",
                "sourceIp": "108.80.167.251",
                "userAgent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0",
            },
            "requestId": "d982df68-9396-4323-a28d-b3d23dd7eb30",
            "routeKey": "$default",
            "stage": "$default",
            "time": "08/Jan/2026:23:31:20 +0000",
            "timeEpoch": 1767915080690,
        },
        "isBase64Encoded": "false",
    }

    # Call the handler
    response = onboarding_logic(event, {})

    # Assertions
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["message"] == "Organizations retrieved successfully"
    assert body["data"] == []


@patch.dict(os.environ, {"CCM_MNA_CONTEXT_TABLE": "test-mna-context"})
@patch("boto3.resource")
def test_onboarding_logic_create_organization(mock_boto_resource):
    clean_imports()

    # Setup mock DynamoDB
    mock_table = MagicMock()
    mock_dynamodb = MagicMock()
    mock_boto_resource.return_value = mock_dynamodb
    mock_dynamodb.Table.return_value = mock_table

    # Import the module after mocking
    from lambdas.onboarding import onboarding_logic

    # Create a sample event for creating an organization
    event = {
        "httpMethod": "POST",
        "path": "/onboarding",
        "queryStringParameters": None,
        "body": json.dumps(
            {
                "company_name": "Test Corp",
                "industry": "Technology",
                "contact_name": "John Doe",
                "contact_email": "john@test.com",
                "scoring_enabled": True,
            }
        ),
    }

    # Call the handler
    response = onboarding_logic(event, {})

    # Assertions
    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    assert body["message"] == "Organization created successfully"
    assert "org_uuid" in body
    assert body["data"]["PK"].startswith("ORG#")
    assert body["data"]["company_info"]["name"] == "Test Corp"

    # Verify put_item was called
    mock_table.put_item.assert_called_once()


@patch.dict(os.environ, {"CCM_MNA_CONTEXT_TABLE": "test-mna-context"})
@patch("boto3.resource")
def test_onboarding_logic_get_organization(mock_boto_resource):
    clean_imports()

    # Setup mock DynamoDB
    mock_table = MagicMock()
    mock_dynamodb = MagicMock()
    mock_boto_resource.return_value = mock_dynamodb
    mock_dynamodb.Table.return_value = mock_table

    # Mock get_item response
    test_org = {
        "PK": "ORG#test-uuid",
        "company_info": {"name": "Test Corp"},
        "contacts": {"ciso": {"email": "test@example.com"}},
        "features": {"scoring_enabled": True},
    }
    mock_table.get_item.return_value = {"Item": test_org}

    # Import the module after mocking
    from lambdas.onboarding import onboarding_logic

    # Create a sample event for getting an organization
    event = {
        "httpMethod": "GET",
        "path": "/onboarding/test-uuid",
        "queryStringParameters": None,
        "body": None,
    }

    # Call the handler
    response = onboarding_logic(event, {})

    # Assertions
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["message"] == "Organization retrieved successfully"
    assert body["data"]["PK"] == "ORG#test-uuid"
