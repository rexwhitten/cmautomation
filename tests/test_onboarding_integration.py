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
    os.environ["CCM_MNA_CONTEXT_TABLE"] = table_name

    print(f"Creating temporary table: {table_name}")
    table = dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{"AttributeName": "PK", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "PK", "AttributeType": "S"}],
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
        "body": json.dumps({"company_name": "Acme Corp", "userId": "user123"}),
    }
    response = onboarding_logic(create_event, {})
    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    org_uuid = body["org_uuid"]
    assert body["data"]["company_info"]["name"] == "Acme Corp"
    assert body["data"]["metadata"]["status"] == "active"

    # 2. Get Onboarding
    get_event = {"httpMethod": "GET", "path": f"/onboarding/{org_uuid}"}
    response = onboarding_logic(get_event, {})
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["data"]["PK"] == f"ORG#{org_uuid}"
    assert body["data"]["company_info"]["name"] == "Acme Corp"

    # 3. Update Organization
    update_event = {
        "httpMethod": "PUT",
        "path": f"/onboarding/{org_uuid}",
        "body": json.dumps(
            {
                "company_name": "Test Corp",
                "contact_name": "John Doe",
                "contact_email": "john@example.com",
            }
        ),
    }
    response = onboarding_logic(update_event, {})
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["message"] == "Organization updated successfully"
    assert body["data"]["company_info"]["name"] == "Test Corp"

    # 4. List Organizations
    list_event = {
        "httpMethod": "GET",
        "path": "/onboarding",
        "queryStringParameters": None,
    }
    response = onboarding_logic(list_event, {})
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert len(body["data"]) >= 1
    # Check if our org is in the list
    found = False
    for item in body["data"]:
        if item["PK"] == f"ORG#{org_uuid}":
            found = True
            assert item["company_info"]["name"] == "Test Corp"
            break
    assert found

    # 5. Delete Organization
    delete_event = {"httpMethod": "DELETE", "path": f"/onboarding/{org_uuid}"}
    response = onboarding_logic(delete_event, {})
    assert response["statusCode"] == 200

    # Verify Deletion
    response = onboarding_logic(get_event, {})
    assert response["statusCode"] == 404
