import pytest
from lambdas.reporting import reporting_logic


def test_reporting_logic_not_implemented():
    with pytest.raises(NotImplementedError):
        reporting_logic({}, {})
