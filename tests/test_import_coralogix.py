import pytest
from lambdas.import_coralogix import import_coralogix_logic


def test_import_coralogix_logic_not_implemented():
    with pytest.raises(NotImplementedError):
        import_coralogix_logic({}, {})
