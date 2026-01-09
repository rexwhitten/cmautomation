import os
import boto3
import mimetypes
import logging
import traceback
import json
import base64
from botocore.exceptions import ClientError

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET = os.environ.get("CCM_MNA_FRONTEND_BUCKET", "my-frontend-bucket")
S3_PREFIX = os.environ.get("CCM_MNA_FRONTEND_BUCKET_KEY_PREFIX", "")
S3_INDEX_FILE = "index.html"
s3 = boto3.client("s3")


def frontend_logic(event, context):
    """
    Lambda function to serve static frontend files from S3 for SPA routing.
    If the requested file is not found, returns index.html for SPA support.
    """
    try:
        logger.info("Processing frontend request", extra={"event": event})

        # Parse the path from the API Gateway event
        path = event.get("rawPath") or event.get("path") or "/"
        if path.startswith("/"):
            path = path[1:]
        if not path or path.endswith("/"):
            path += S3_INDEX_FILE

        logger.info(f"Resolved object path: {path}")

        # Prepend prefix if set
        s3_key = f"{S3_PREFIX}{path}"

        try:
            s3_response = s3.get_object(Bucket=S3_BUCKET, Key=s3_key)
            content = s3_response["Body"].read()
            content_type = mimetypes.guess_type(path)[0] or "application/octet-stream"

            logger.info(
                f"Successfully retrieved object: {s3_key}, Content-Type: {content_type}"
            )

            is_text = content_type.startswith("text/") or content_type in [
                "application/json",
                "application/javascript",
                "application/xml",
            ]

            return {
                "statusCode": 200,
                "headers": {"Content-Type": content_type, "Cache-Control": "max-age=0"},
                "body": (
                    content.decode("utf-8")
                    if is_text
                    else (base64.b64encode(content).decode("utf-8"))
                ),
                "isBase64Encoded": not is_text,
            }
        except ClientError as e:
            if e.response["Error"]["Code"] == "NoSuchKey":
                logger.warning(
                    f"File not found: {s3_key}, falling back to {S3_INDEX_FILE}"
                )
                # Fallback to index.html for SPA routing
                fallback_key = f"{S3_PREFIX}{S3_INDEX_FILE}"
                s3_response = s3.get_object(Bucket=S3_BUCKET, Key=fallback_key)
                content = s3_response["Body"].read()
                return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "text/html"},
                    "body": content.decode("utf-8"),
                    "isBase64Encoded": False,
                }
            else:
                logger.error(f"S3 ClientError: {str(e)}", exc_info=True)
                raise e

    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Internal Server Error", "details": str(e)}),
        }
