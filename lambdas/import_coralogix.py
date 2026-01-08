import boto3
import json
import os
import logging
from datetime import datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from mypy_boto3_s3.client import S3Client

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3: "S3Client" = boto3.client("s3")  # type: ignore
FRONTEND_BUCKET = os.environ.get("CCM_MNA_FRONTEND_BUCKET")


def import_coralogix_logic(event, context):
    """
    Logic for importing Coralogix security posture data.
    Accepts POST data and stores it in S3.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    if not FRONTEND_BUCKET:
        logger.error("CCM_MNA_FRONTEND_BUCKET environment variable not set")
        return {"statusCode": 500, "body": "Configuration error"}

    # Parse the body if it's a string
    body = event.get("body", {})
    if isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            return {"statusCode": 400, "body": "Invalid JSON in request body"}

    # Generate a unique run ID based on timestamp
    run_id = datetime.utcnow().strftime("%Y%m%d_%H%M%S")

    # S3 key structure: data/import_coralogix/{run_id}/data.json
    s3_key = f"data/import_coralogix/{run_id}/data.json"

    try:
        # Store the data in S3
        s3.put_object(
            Bucket=FRONTEND_BUCKET,
            Key=s3_key,
            Body=json.dumps(body),
            ContentType="application/json",
        )

        logger.info(f"Successfully stored data at s3://{FRONTEND_BUCKET}/{s3_key}")

        return {
            "statusCode": 201,
            "body": json.dumps(
                {
                    "message": "Data imported successfully",
                    "run_id": run_id,
                    "s3_location": f"s3://{FRONTEND_BUCKET}/{s3_key}",
                }
            ),
        }
    except Exception as e:
        logger.error(f"Error storing data in S3: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
