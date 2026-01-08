import json
from unittest.mock import patch, MagicMock
from lambdas.import_katana import import_katana_logic


def test_import_katana_logic_with_data():
    """Test import_katana with POST data and S3 storage"""
    test_data = {
        "findings": [
            {"resource_id": "katana-12345", "severity": "high"},
            {"resource_id": "katana-67890", "severity": "medium"},
        ]
    }

    event = {"body": json.dumps(test_data)}
    context = {}

    with patch("lambdas.import_katana.s3") as mock_s3:
        with patch("lambdas.import_katana.FRONTEND_BUCKET", "test-bucket"):
            result = import_katana_logic(event, context)

            # Verify S3 put_object was called
            assert mock_s3.put_object.called
            call_args = mock_s3.put_object.call_args[1]
            assert call_args["Bucket"] == "test-bucket"
            assert "data/import_katana/" in call_args["Key"]
            assert call_args["ContentType"] == "application/json"

            # Verify response
            assert result["statusCode"] == 201
            body = json.loads(result["body"])
            assert "run_id" in body
            assert "s3_location" in body


def test_import_katana_logic_missing_bucket():
    """Test import_katana when bucket environment variable is not set"""
    event = {"body": json.dumps({"test": "data"})}
    context = {}

    with patch("lambdas.import_katana.FRONTEND_BUCKET", None):
        result = import_katana_logic(event, context)
        assert result["statusCode"] == 500
