import pytest
from lambdas.import_azure import import_azure_logic


def test_import_azure_logic_not_implemented():
    with pytest.raises(NotImplementedError):
        import_azure_logic({}, {})
