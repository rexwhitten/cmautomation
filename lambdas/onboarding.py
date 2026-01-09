import json
import boto3
import uuid
import logging
from datetime import datetime, timezone
from decimal import Decimal
from boto3.dynamodb.conditions import Key
import os

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource("dynamodb")
context_table_name = os.environ.get("CCM_MNA_CONTEXT_TABLE", "mna_context")
context_table = dynamodb.Table(context_table_name)


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


def validate_organization_data(data):
    """Validate required fields for organization onboarding"""
    required_fields = ["company_name"]
    missing_fields = [field for field in required_fields if not data.get(field)]

    if missing_fields:
        return False, f"Missing required fields: {', '.join(missing_fields)}"

    return True, None


def create_organization(event_body):
    """Create a new organization record in mna_context table"""
    try:
        logger.info(
            "Creating new organization",
            extra={"event_body_keys": list(event_body.keys())},
        )

        # Validate input
        is_valid, error_msg = validate_organization_data(event_body)
        if not is_valid:
            logger.warning("Organization validation failed", extra={"error": error_msg})
            return response(400, {"error": error_msg})

        org_uuid = str(uuid.uuid4())
        logger.info("Generated organization UUID", extra={"org_uuid": org_uuid})

        # Build the organization item according to data model
        item = {
            "PK": f"ORG#{org_uuid}",
            "company_info": {
                "name": event_body.get("company_name", ""),
                "industry": event_body.get("industry", ""),
                "target_company": event_body.get("target_company", ""),
            },
            "contacts": {
                "ciso": {
                    "name": event_body.get("contact_name", ""),
                    "email": event_body.get("contact_email", ""),
                    "phone": event_body.get("contact_phone", ""),
                },
                "remediation": event_body.get("remediation_contact", {}),
            },
            "features": {
                "scoring_enabled": event_body.get("scoring_enabled", True),
            },
            "metadata": {
                "created_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "status": "active",
            },
        }

        context_table.put_item(Item=item)
        logger.info(
            "Organization created successfully",
            extra={"org_uuid": org_uuid, "company_name": item["company_info"]["name"]},
        )

        return response(
            201,
            {
                "message": "Organization created successfully",
                "org_uuid": org_uuid,
                "data": item,
            },
        )

    except Exception as e:
        logger.error(
            "Failed to create organization",
            exc_info=True,
            extra={"error_type": type(e).__name__, "error_message": str(e)},
        )
        return response(
            500, {"error": "Failed to create organization", "details": str(e)}
        )


def get_organization(org_uuid):
    """Retrieve an organization record"""
    try:
        result = context_table.get_item(Key={"PK": f"ORG#{org_uuid}"})

        if "Item" not in result:
            return response(404, {"error": "Organization not found"})

        return response(
            200,
            {"message": "Organization retrieved successfully", "data": result["Item"]},
        )

    except Exception as e:
        print(f"Error retrieving organization: {str(e)}")
        return response(
            500, {"error": "Failed to retrieve organization", "details": str(e)}
        )


def update_organization(org_uuid, event_body):
    """Update organization information"""
    try:
        # Get current record
        result = context_table.get_item(Key={"PK": f"ORG#{org_uuid}"})
        if "Item" not in result:
            return response(404, {"error": "Organization not found"})

        timestamp = datetime.now(timezone.utc).isoformat()

        # Build update expression
        update_parts = ["metadata.updated_at = :timestamp"]
        expression_values = {":timestamp": timestamp}

        # Update company info if provided
        if (
            "company_name" in event_body
            or "industry" in event_body
            or "target_company" in event_body
        ):
            if "company_name" in event_body:
                update_parts.append("company_info.#name = :company_name")
                expression_values[":company_name"] = event_body["company_name"]
            if "industry" in event_body:
                update_parts.append("company_info.industry = :industry")
                expression_values[":industry"] = event_body["industry"]
            if "target_company" in event_body:
                update_parts.append("company_info.target_company = :target_company")
                expression_values[":target_company"] = event_body["target_company"]

        # Update contacts if provided
        if (
            "contact_name" in event_body
            or "contact_email" in event_body
            or "contact_phone" in event_body
        ):
            if "contact_name" in event_body:
                update_parts.append("contacts.ciso.#name = :contact_name")
                expression_values[":contact_name"] = event_body["contact_name"]
            if "contact_email" in event_body:
                update_parts.append("contacts.ciso.email = :contact_email")
                expression_values[":contact_email"] = event_body["contact_email"]
            if "contact_phone" in event_body:
                update_parts.append("contacts.ciso.phone = :contact_phone")
                expression_values[":contact_phone"] = event_body["contact_phone"]

        # Update features if provided
        if "scoring_enabled" in event_body:
            update_parts.append("features.scoring_enabled = :scoring_enabled")
            expression_values[":scoring_enabled"] = event_body["scoring_enabled"]

        update_expression = "SET " + ", ".join(update_parts)
        expression_names = (
            {"#name": "name"}
            if "company_name" in event_body or "contact_name" in event_body
            else None
        )

        update_kwargs = {
            "Key": {"PK": f"ORG#{org_uuid}"},
            "UpdateExpression": update_expression,
            "ExpressionAttributeValues": expression_values,
            "ReturnValues": "ALL_NEW",
        }

        if expression_names:
            update_kwargs["ExpressionAttributeNames"] = expression_names

        updated_item = context_table.update_item(**update_kwargs)

        updated_item = context_table.update_item(**update_kwargs)

        return response(
            200,
            {
                "message": "Organization updated successfully",
                "data": updated_item["Attributes"],
            },
        )

    except Exception as e:
        print(f"Error updating organization: {str(e)}")
        return response(
            500, {"error": "Failed to update organization", "details": str(e)}
        )


def list_organizations(query_params):
    """List organization records"""
    try:
        # Get pagination parameters
        limit = int(query_params.get("limit", 50))
        last_key = query_params.get("lastKey")

        scan_kwargs = {"Limit": limit}

        if last_key:
            scan_kwargs["ExclusiveStartKey"] = {"PK": last_key}

        result = context_table.scan(**scan_kwargs)

        result = context_table.scan(**scan_kwargs)

        response_data = {
            "message": "Organizations retrieved successfully",
            "data": result.get("Items", []),
            "count": len(result.get("Items", [])),
        }

        if "LastEvaluatedKey" in result:
            response_data["lastKey"] = result["LastEvaluatedKey"]["PK"]

        return response(200, response_data)

    except Exception as e:
        print(f"Error listing organizations: {str(e)}")
        return response(
            500, {"error": "Failed to list organizations", "details": str(e)}
        )


def delete_organization(org_uuid):
    """Delete an organization record"""
    try:
        # Check if record exists
        result = context_table.get_item(Key={"PK": f"ORG#{org_uuid}"})
        if "Item" not in result:
            return response(404, {"error": "Organization not found"})

        context_table.delete_item(Key={"PK": f"ORG#{org_uuid}"})

        return response(
            200,
            {
                "message": "Organization deleted successfully",
                "org_uuid": org_uuid,
            },
        )

    except Exception as e:
        print(f"Error deleting organization: {str(e)}")
        return response(
            500, {"error": "Failed to delete organization", "details": str(e)}
        )


def onboarding_logic(event, context):
    """Main Lambda handler"""
    try:
        print(f"Received event: {json.dumps(event)}")

        http_method = event.get("httpMethod")
        if not http_method:
            # Try to get HTTP method from requestContext (API Gateway HTTP API v2)
            http_method = (
                event.get("requestContext", {}).get("http", {}).get("method", "")
            )

        # Handle both API Gateway V1 (path) and V2 (rawPath)
        path = event.get("rawPath") or event.get("path") or "/"
        query_params = event.get("queryStringParameters") or {}

        # Parse body if present
        body = {}
        if event.get("body"):
            body = json.loads(event.get("body"))

        # Extract org_uuid from path if present
        path_parts = path.strip("/").split("/")
        org_uuid = path_parts[1] if len(path_parts) > 1 else None

        # Handle OPTIONS for CORS
        if http_method == "OPTIONS":
            return response(200, {"message": "OK"})

        # Route requests based on new data model
        # Allow POST to root path "/" (when accessed via Function URL) or "/onboarding" (when local/API Gateway)
        if http_method == "POST" and (path == "/onboarding" or path == "/"):
            return create_organization(body)

        elif http_method == "GET" and (path == "/onboarding" or path == "/"):
            return list_organizations(query_params)

        elif http_method == "GET" and org_uuid:
            return get_organization(org_uuid)

        elif http_method == "PUT" and org_uuid:
            return update_organization(org_uuid, body)

        elif http_method == "DELETE" and org_uuid:
            return delete_organization(org_uuid)

        else:
            return response(404, {"error": "Route not found"})

    except Exception as e:
        print(f"Unhandled error: {str(e)}")
        return response(500, {"error": "Internal server error", "details": str(e)})
