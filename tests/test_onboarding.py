import pytest
from lambdas.onboarding import onboarding_logic


def test_onboarding_logic_not_implemented():
    with pytest.raises(NotImplementedError):
        onboarding_logic({}, {})
