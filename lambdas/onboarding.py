import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal
from boto3.dynamodb.conditions import Key
import os

# Initialize DynamoDB client
dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("DYNAMODB_TABLE", "mna-onboarding")
table = dynamodb.Table(table_name)


class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert DynamoDB Decimal types to JSON"""

    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def response(status_code, body):
    """Generate API Gateway response"""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
        },
        "body": json.dumps(body, cls=DecimalEncoder),
    }


def validate_step_data(step, data):
    """Validate required fields for each step"""
    validations = {
        1: ["companyName", "contactName", "contactEmail"],
        2: ["transactionType", "targetCompany", "dealStage"],
        3: ["cloudProviders"],
        4: ["focusAreas"],
    }

    required_fields = validations.get(step, [])
    missing_fields = [field for field in required_fields if not data.get(field)]

    if missing_fields:
        return False, f"Missing required fields: {', '.join(missing_fields)}"

    return True, None


def create_onboarding(event_body):
    """Create a new onboarding record"""
    try:
        onboarding_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()

        item = {
            "onboardingId": onboarding_id,
            "userId": event_body.get("userId", ""),
            "createdAt": timestamp,
            "updatedAt": timestamp,
            "currentStep": 1,
            "status": "draft",
            "companyName": event_body.get("companyName", ""),
            "contactName": event_body.get("contactName", ""),
            "contactEmail": event_body.get("contactEmail", ""),
            "contactPhone": event_body.get("contactPhone", ""),
            "formData": {},
        }

        table.put_item(Item=item)

        return response(
            201,
            {
                "message": "Onboarding created successfully",
                "onboardingId": onboarding_id,
                "data": item,
            },
        )

    except Exception as e:
        print(f"Error creating onboarding: {str(e)}")
        return response(
            500, {"error": "Failed to create onboarding", "details": str(e)}
        )


def get_onboarding(onboarding_id):
    """Retrieve an onboarding record"""
    try:
        result = table.get_item(Key={"onboardingId": onboarding_id})

        if "Item" not in result:
            return response(404, {"error": "Onboarding not found"})

        return response(
            200,
            {"message": "Onboarding retrieved successfully", "data": result["Item"]},
        )

    except Exception as e:
        print(f"Error retrieving onboarding: {str(e)}")
        return response(
            500, {"error": "Failed to retrieve onboarding", "details": str(e)}
        )


def update_onboarding_step(onboarding_id, event_body):
    """Update onboarding with step data"""
    try:
        step = event_body.get("step")
        step_data = event_body.get("data", {})

        if not step:
            return response(400, {"error": "Step number is required"})

        # Validate step data
        is_valid, error_msg = validate_step_data(step, step_data)
        if not is_valid:
            return response(400, {"error": error_msg})

        # Get current record
        result = table.get_item(Key={"onboardingId": onboarding_id})
        if "Item" not in result:
            return response(404, {"error": "Onboarding not found"})

        current_item = result["Item"]
        timestamp = datetime.utcnow().isoformat()

        # Update based on step
        update_expression_parts = ["updatedAt = :timestamp", "currentStep = :step"]
        expression_values = {":timestamp": timestamp, ":step": step}

        # Store step-specific data
        if step == 1:
            update_expression_parts.extend(
                [
                    "companyName = :companyName",
                    "contactName = :contactName",
                    "contactEmail = :contactEmail",
                    "contactPhone = :contactPhone",
                ]
            )
            expression_values.update(
                {
                    ":companyName": step_data.get("companyName", ""),
                    ":contactName": step_data.get("contactName", ""),
                    ":contactEmail": step_data.get("contactEmail", ""),
                    ":contactPhone": step_data.get("contactPhone", ""),
                }
            )

        elif step == 2:
            update_expression_parts.extend(
                [
                    "transactionType = :transactionType",
                    "targetCompany = :targetCompany",
                    "dealStage = :dealStage",
                    "expectedCloseDate = :expectedCloseDate",
                ]
            )
            expression_values.update(
                {
                    ":transactionType": step_data.get("transactionType", ""),
                    ":targetCompany": step_data.get("targetCompany", ""),
                    ":dealStage": step_data.get("dealStage", ""),
                    ":expectedCloseDate": step_data.get("expectedCloseDate", ""),
                }
            )

        elif step == 3:
            update_expression_parts.extend(
                [
                    "cloudProviders = :cloudProviders",
                    "accountCount = :accountCount",
                    "workloadTypes = :workloadTypes",
                ]
            )
            expression_values.update(
                {
                    ":cloudProviders": step_data.get("cloudProviders", []),
                    ":accountCount": step_data.get("accountCount", ""),
                    ":workloadTypes": step_data.get("workloadTypes", ""),
                }
            )

        elif step == 4:
            update_expression_parts.extend(
                [
                    "focusAreas = :focusAreas",
                    "complianceFrameworks = :complianceFrameworks",
                    "additionalNotes = :additionalNotes",
                ]
            )
            expression_values.update(
                {
                    ":focusAreas": step_data.get("focusAreas", []),
                    ":complianceFrameworks": step_data.get("complianceFrameworks", []),
                    ":additionalNotes": step_data.get("additionalNotes", ""),
                }
            )

        # Execute update
        update_expression = "SET " + ", ".join(update_expression_parts)

        updated_item = table.update_item(
            Key={"onboardingId": onboarding_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values,
            ReturnValues="ALL_NEW",
        )

        return response(
            200,
            {
                "message": f"Step {step} updated successfully",
                "data": updated_item["Attributes"],
            },
        )

    except Exception as e:
        print(f"Error updating onboarding step: {str(e)}")
        return response(
            500, {"error": "Failed to update onboarding", "details": str(e)}
        )


def submit_onboarding(onboarding_id, event_body):
    """Finalize and submit the onboarding"""
    try:
        # Get current record
        result = table.get_item(Key={"onboardingId": onboarding_id})
        if "Item" not in result:
            return response(404, {"error": "Onboarding not found"})

        timestamp = datetime.utcnow().isoformat()

        # Update status to completed
        updated_item = table.update_item(
            Key={"onboardingId": onboarding_id},
            UpdateExpression="SET #status = :status, updatedAt = :timestamp, submittedAt = :timestamp",
            ExpressionAttributeNames={"#status": "status"},
            ExpressionAttributeValues={":status": "submitted", ":timestamp": timestamp},
            ReturnValues="ALL_NEW",
        )

        # Here you could add additional logic like:
        # - Send notification emails
        # - Trigger assessment workflows
        # - Create tickets in project management systems

        return response(
            200,
            {
                "message": "Onboarding submitted successfully",
                "data": updated_item["Attributes"],
            },
        )

    except Exception as e:
        print(f"Error submitting onboarding: {str(e)}")
        return response(
            500, {"error": "Failed to submit onboarding", "details": str(e)}
        )


def list_onboarding_records(query_params):
    """List onboarding records with optional filtering"""
    try:
        # Get pagination parameters
        limit = int(query_params.get("limit", 50))
        last_key = query_params.get("lastKey")
        status_filter = query_params.get("status")

        scan_kwargs = {"Limit": limit}

        if last_key:
            scan_kwargs["ExclusiveStartKey"] = {"onboardingId": last_key}

        if status_filter:
            scan_kwargs["FilterExpression"] = Key("status").eq(status_filter)

        result = table.scan(**scan_kwargs)

        response_data = {
            "message": "Onboarding records retrieved successfully",
            "data": result.get("Items", []),
            "count": len(result.get("Items", [])),
        }

        if "LastEvaluatedKey" in result:
            response_data["lastKey"] = result["LastEvaluatedKey"]["onboardingId"]

        return response(200, response_data)

    except Exception as e:
        print(f"Error listing onboarding records: {str(e)}")
        return response(
            500, {"error": "Failed to list onboarding records", "details": str(e)}
        )


def delete_onboarding(onboarding_id):
    """Delete an onboarding record"""
    try:
        # Check if record exists
        result = table.get_item(Key={"onboardingId": onboarding_id})
        if "Item" not in result:
            return response(404, {"error": "Onboarding not found"})

        table.delete_item(Key={"onboardingId": onboarding_id})

        return response(
            200,
            {
                "message": "Onboarding deleted successfully",
                "onboardingId": onboarding_id,
            },
        )

    except Exception as e:
        print(f"Error deleting onboarding: {str(e)}")
        return response(
            500, {"error": "Failed to delete onboarding", "details": str(e)}
        )


def onboarding_logic(event, context):
    """Main Lambda handler"""
    try:
        print(f"Received event: {json.dumps(event)}")

        http_method = event.get("httpMethod", "")
        path = event.get("path", "")
        query_params = event.get("queryStringParameters") or {}

        # Parse body if present
        body = {}
        if event.get("body"):
            body = json.loads(event.get("body"))

        # Extract onboarding ID from path if present
        path_parts = path.strip("/").split("/")
        onboarding_id = path_parts[1] if len(path_parts) > 1 else None

        # Handle OPTIONS for CORS
        if http_method == "OPTIONS":
            return response(200, {"message": "OK"})

        # Route requests
        if http_method == "POST" and path == "/onboarding":
            return create_onboarding(body)

        elif http_method == "GET" and path == "/onboarding":
            return list_onboarding_records(query_params)

        elif http_method == "GET" and onboarding_id:
            return get_onboarding(onboarding_id)

        elif http_method == "PUT" and onboarding_id and "step" in body:
            return update_onboarding_step(onboarding_id, body)

        elif http_method == "POST" and onboarding_id and path.endswith("/submit"):
            return submit_onboarding(onboarding_id, body)

        elif http_method == "DELETE" and onboarding_id:
            return delete_onboarding(onboarding_id)

        else:
            return response(404, {"error": "Route not found"})

    except Exception as e:
        print(f"Unhandled error: {str(e)}")
        return response(500, {"error": "Internal server error", "details": str(e)})
