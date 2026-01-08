from lambdas.reporting import reporting_logic


def test_reporting_logic_not_implemented():
    result = reporting_logic({}, {})
    assert result["statusCode"] == 501
    assert "NotImplementedError" in result["errors"][0]
