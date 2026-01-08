from lambdas.remediation_planning import remediation_planning_logic


def test_remediation_planning_logic_not_implemented():
    result = remediation_planning_logic({}, {})
    assert result["statusCode"] == 501
    assert "NotImplementedError" in result["errors"][0]
