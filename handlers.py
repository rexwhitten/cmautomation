from lambdas.onboarding import onboarding_logic
from lambdas.import_aws import import_aws_logic
from lambdas.import_azure import import_azure_logic
from lambdas.import_wiz import import_wiz_logic
from lambdas.import_katana import import_katana_logic
from lambdas.import_coralogix import import_coralogix_logic
from lambdas.remediation_planning import remediation_planning_logic
from lambdas.reporting import reporting_logic


def onboarding_handler(event, context):
    return onboarding_logic(event, context)


def import_aws_handler(event, context):
    return import_aws_logic(event, context)


def import_azure_handler(event, context):
    return import_azure_logic(event, context)


def import_wiz_handler(event, context):
    return import_wiz_logic(event, context)


def import_katana_handler(event, context):
    return import_katana_logic(event, context)


def import_coralogix_handler(event, context):
    return import_coralogix_logic(event, context)


def remediation_planning_handler(event, context):
    return remediation_planning_logic(event, context)


def reporting_handler(event, context):
    return reporting_logic(event, context)
