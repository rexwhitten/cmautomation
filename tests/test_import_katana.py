import pytest
from lambdas.import_katana import import_katana_logic


def test_import_katana_logic_not_implemented():
    with pytest.raises(NotImplementedError):
        import_katana_logic({}, {})
