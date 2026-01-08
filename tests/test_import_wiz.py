import json
from unittest.mock import patch, MagicMock
from lambdas.import_wiz import import_wiz_logic


def test_import_wiz_logic_with_data():
    """Test import_wiz with POST data and S3 storage"""
    test_data = {
        "findings": [
            {"resource_id": "wiz-12345", "severity": "critical"},
            {"resource_id": "wiz-67890", "severity": "high"},
        ]
    }

    event = {"body": json.dumps(test_data)}
    context = {}

    with patch("lambdas.import_wiz.s3") as mock_s3:
        with patch("lambdas.import_wiz.FRONTEND_BUCKET", "test-bucket"):
            result = import_wiz_logic(event, context)

            # Verify S3 put_object was called
            assert mock_s3.put_object.called
            call_args = mock_s3.put_object.call_args[1]
            assert call_args["Bucket"] == "test-bucket"
            assert "data/import_wiz/" in call_args["Key"]
            assert call_args["ContentType"] == "application/json"

            # Verify response
            assert result["statusCode"] == 201
            body = json.loads(result["body"])
            assert "run_id" in body
            assert "s3_location" in body


def test_import_wiz_logic_missing_bucket():
    """Test import_wiz when bucket environment variable is not set"""
    event = {"body": json.dumps({"test": "data"})}
    context = {}

    with patch("lambdas.import_wiz.FRONTEND_BUCKET", None):
        result = import_wiz_logic(event, context)
        assert result["statusCode"] == 500
