import boto3
import json
import os
import pytest
import uuid
import time


@pytest.fixture
def dynamodb():
    """Real DynamoDB resource using available AWS credentials."""
    return boto3.resource("dynamodb", region_name="us-east-1")


@pytest.fixture
def onboarding_table(dynamodb):
    """Creates a temporary DynamoDB table in AWS for testing."""
    table_name = f"test-onboarding-{uuid.uuid4()}"
    os.environ["DYNAMODB_TABLE"] = table_name

    print(f"Creating temporary table: {table_name}")
    table = dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{"AttributeName": "onboardingId", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "onboardingId", "AttributeType": "S"}],
        ProvisionedThroughput={"ReadCapacityUnits": 5, "WriteCapacityUnits": 5},
    )

    # Wait for table to be active
    print("Waiting for table to be active...")
    table.meta.client.get_waiter("table_exists").wait(TableName=table_name)

    yield table

    # Cleanup
    print(f"Deleting temporary table: {table_name}")
    try:
        table.delete()
        table.meta.client.get_waiter("table_not_exists").wait(TableName=table_name)
    except Exception as e:
        print(f"Failed to delete table {table_name}: {e}")


def test_onboarding_lifecycle(onboarding_table):
    # Import the lambda handler here to ensure it uses the mocked environment
    import sys
    import importlib
    from lambdas import onboarding

    importlib.reload(onboarding)
    from lambdas.onboarding import onboarding_logic

    # 1. Create Onboarding
    create_event = {
        "httpMethod": "POST",
        "path": "/onboarding",
        "body": json.dumps({"userId": "user123"}),
    }
    response = onboarding_logic(create_event, {})
    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    onboarding_id = body["data"]["onboardingId"]
    assert body["data"]["userId"] == "user123"
    assert body["data"]["status"] == "draft"

    # 2. Get Onboarding
    get_event = {"httpMethod": "GET", "path": f"/onboarding/{onboarding_id}"}
    response = onboarding_logic(get_event, {})
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["data"]["onboardingId"] == onboarding_id

    # 3. Update Step 1
    update_event = {
        "httpMethod": "PUT",
        "path": f"/onboarding/{onboarding_id}/step",
        "body": json.dumps(
            {
                "step": 1,
                "data": {
                    "companyName": "Test Corp",
                    "contactName": "John Doe",
                    "contactEmail": "john@example.com",
                    "contactPhone": "555-0123",
                },
            }
        ),
    }
    response = onboarding_logic(update_event, {})
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["data"]["companyName"] == "Test Corp"
    assert body["data"]["currentStep"] == 1

    # 4. List Onboarding Records
    list_event = {
        "httpMethod": "GET",
        "path": "/onboarding",
        "queryStringParameters": None,
    }
    response = onboarding_logic(list_event, {})
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert len(body["data"]) == 1
    assert body["data"][0]["companyName"] == "Test Corp"

    # 5. Delete Onboarding
    delete_event = {"httpMethod": "DELETE", "path": f"/onboarding/{onboarding_id}"}
    response = onboarding_logic(delete_event, {})
    assert response["statusCode"] == 200

    # Verify Deletion
    response = onboarding_logic(get_event, {})
    assert response["statusCode"] == 404
