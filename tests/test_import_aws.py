import pytest
from lambdas.import_aws import import_aws_logic


def test_import_aws_logic_not_implemented():
    with pytest.raises(NotImplementedError):
        import_aws_logic({}, {})
