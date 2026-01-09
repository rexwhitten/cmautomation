import boto3
import os
import json
import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from mypy_boto3_dynamodb.service_resource import DynamoDBServiceResource
    from mypy_boto3_s3.client import S3Client

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb: "DynamoDBServiceResource" = boto3.resource("dynamodb")  # type: ignore
s3: "S3Client" = boto3.client("s3")  # type: ignore

SCORING_TABLE = os.environ.get("CCM_MNA_SCORING_TABLE")


def scoring_logic(event, context):
    """
    Scoring Lambda Logic

    Reads findings data from S3 (expected via event or predetermined path)
    and creates records in the Scoring DynamoDB table.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    if not SCORING_TABLE:
        logger.error("CCM_MNA_SCORING_TABLE environment variable not set")
        return {"statusCode": 500, "body": "Configuration error"}

    table = dynamodb.Table(SCORING_TABLE)

    # Example: Process S3 event records
    # This assumes the event is an S3 notification event.
    # If it is a direct invocation with a payload, this logic might need adjustment.

    records = event.get("Records", [])
    processed_count = 0

    for record in records:
        if record.get("eventSource") == "aws:s3":
            bucket_name = record["s3"]["bucket"]["name"]
            key = record["s3"]["object"]["key"]

            logger.info(f"Processing file: s3://{bucket_name}/{key}")

            try:
                response = s3.get_object(Bucket=bucket_name, Key=key)
                content = response["Body"].read().decode("utf-8")
                findings = json.loads(content)

                # Assume findings is a list of dicts suitable for scoring conversion
                for finding in findings:
                    # TODO: Implement actual scoring logic here
                    # Mapping generic finding data to DynamoDB Scoring Item structure

                    item = {
                        "PK": f"RESOURCE#{finding.get('resource_id', 'unknown')}",
                        "SK": f"STATE#{finding.get('timestamp', 'LATEST')}",
                        "score": finding.get("score", 0),
                        "details": finding.get("details", {}),
                    }

                    table.put_item(Item=item)
                    processed_count += 1

            except Exception as e:
                logger.error(f"Error processing file {key}: {str(e)}")
                continue

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Scoring processing complete",
                "processed_records": processed_count,
            }
        ),
    }
