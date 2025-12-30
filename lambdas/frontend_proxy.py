import os
import boto3
import mimetypes
from botocore.exceptions import ClientError

S3_BUCKET = os.environ.get("FRONTEND_BUCKET", "my-frontend-bucket")
S3_INDEX_FILE = "index.html"
s3 = boto3.client("s3")


def lambda_handler(event, context):
    """
    Lambda function to serve static frontend files from S3 for SPA routing.
    If the requested file is not found, returns index.html for SPA support.
    """
    # Parse the path from the API Gateway event
    path = event.get("rawPath") or event.get("path") or "/"
    if path.startswith("/"):
        path = path[1:]
    if not path or path.endswith("/"):
        path += S3_INDEX_FILE

    try:
        s3_response = s3.get_object(Bucket=S3_BUCKET, Key=path)
        content = s3_response["Body"].read()
        content_type = mimetypes.guess_type(path)[0] or "application/octet-stream"
        return {
            "statusCode": 200,
            "headers": {"Content-Type": content_type},
            "body": (
                content.decode("utf-8") if content_type.startswith("text/") else content
            ),
            "isBase64Encoded": not content_type.startswith("text/"),
        }
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            # Fallback to index.html for SPA routing
            s3_response = s3.get_object(Bucket=S3_BUCKET, Key=S3_INDEX_FILE)
            content = s3_response["Body"].read()
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "text/html"},
                "body": content.decode("utf-8"),
                "isBase64Encoded": False,
            }
        else:
            return {"statusCode": 500, "body": "Internal server error"}
