import pytest
from lambdas.remediation_planning import remediation_planning_logic


def test_remediation_planning_logic_not_implemented():
    with pytest.raises(NotImplementedError):
        remediation_planning_logic({}, {})
