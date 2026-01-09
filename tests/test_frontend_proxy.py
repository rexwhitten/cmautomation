import os
import boto3
import pytest
import json
from unittest.mock import MagicMock, patch


@pytest.fixture
def mock_env():
    with patch.dict(
        os.environ,
        {
            "CCM_MNA_FRONTEND_BUCKET": "test-bucket",
            "CCM_MNA_FRONTEND_BUCKET_KEY_PREFIX": "frontend/",
        },
    ):
        yield


def test_frontend_proxy_integration_paths(mock_env):
    """
    Verify that the frontend proxy correctly handles paths and prefixes
    to match the S3 structure defined in Terraform.
    """
    # Clean import to ensure env vars are picked up
    import sys

    if "lambdas.frontend_proxy" in sys.modules:
        del sys.modules["lambdas.frontend_proxy"]

    from lambdas.frontend_proxy import frontend_logic

    # Mock S3
    mock_s3 = MagicMock()

    with patch("lambdas.frontend_proxy.s3", mock_s3):
        # Setup mock response
        mock_body = MagicMock()
        mock_body.read.return_value = b"<html>Index</html>"
        mock_s3.get_object.return_value = {"Body": mock_body}

        # Case 1: Root request -> should fetch frontend/index.html
        response = frontend_logic({"rawPath": "/"}, {})

        assert response["statusCode"] == 200
        args, kwargs = mock_s3.get_object.call_args_list[-1]
        assert kwargs["Bucket"] == "test-bucket"
        assert kwargs["Key"] == "frontend/index.html"

        # Case 2: Specific file request -> should fetch frontend/app.js
        response = frontend_logic({"rawPath": "/app.js"}, {})

        assert response["statusCode"] == 200
        args, kwargs = mock_s3.get_object.call_args_list[-1]
        assert kwargs["Key"] == "frontend/app.js"

        # Case 3: Deep path request -> should fetch frontend/assets/style.css
        response = frontend_logic({"rawPath": "/assets/style.css"}, {})

        assert response["statusCode"] == 200
        args, kwargs = mock_s3.get_object.call_args_list[-1]
        assert kwargs["Key"] == "frontend/assets/style.css"


if __name__ == "__main__":
    pytest.main([__file__])
