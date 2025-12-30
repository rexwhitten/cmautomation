import pytest
from lambdas.import_wiz import import_wiz_logic


def test_import_wiz_logic_not_implemented():
    with pytest.raises(NotImplementedError):
        import_wiz_logic({}, {})
