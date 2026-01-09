# CloudWatch Log Groups for Lambda Functions
# Centralized logging configuration with retention policies

resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.functions

  name              = "/aws/lambda/${var.project_name}-${var.environment}-${each.key}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.tags,
    {
      Name     = "${var.project_name}-${var.environment}-${each.key}-logs"
      Function = each.key
    }
  )
}

# CloudWatch Log Metric Filters for Error Tracking
resource "aws_cloudwatch_log_metric_filter" "lambda_errors" {
  for_each = local.functions

  name           = "${var.project_name}-${var.environment}-${each.key}-errors"
  log_group_name = aws_cloudwatch_log_group.lambda_logs[each.key].name
  pattern        = "[time, request_id, level = ERROR*, ...]"

  metric_transformation {
    name      = "${var.project_name}-${var.environment}-${each.key}-ErrorCount"
    namespace = "${var.project_name}/${var.environment}/Lambda"
    value     = "1"
    unit      = "Count"
  }
}

# CloudWatch Alarms for High Error Rates
resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  for_each = local.functions

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "${var.project_name}-${var.environment}-${each.key}-ErrorCount"
  namespace           = "${var.project_name}/${var.environment}/Lambda"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors lambda error rate for ${each.key}"
  treat_missing_data  = "notBreaching"

  tags = merge(
    local.tags,
    {
      Name     = "${var.project_name}-${var.environment}-${each.key}-error-alarm"
      Function = each.key
    }
  )
}

# CloudWatch Dashboard for Lambda Monitoring
resource "aws_cloudwatch_dashboard" "lambda_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-lambda-monitoring"

  dashboard_body = jsonencode({
    widgets = concat(
      # Error widgets
      [
        for key, value in local.functions : {
          type = "metric"
          properties = {
            metrics = [
              ["${var.project_name}/${var.environment}/Lambda", "${var.project_name}-${var.environment}-${key}-ErrorCount", { stat = "Sum" }],
              ["AWS/Lambda", "Errors", "FunctionName", "${var.project_name}-${var.environment}-${key}", { stat = "Sum" }]
            ]
            period = 300
            stat   = "Sum"
            region = data.aws_region.current.name
            title  = "${key} - Errors"
            yAxis = {
              left = {
                min = 0
              }
            }
          }
          width  = 6
          height = 6
          x      = (index(keys(local.functions), key) % 4) * 6
          y      = floor(index(keys(local.functions), key) / 4) * 12
        }
      ],
      # Duration widgets
      [
        for key, value in local.functions : {
          type = "metric"
          properties = {
            metrics = [
              ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-${var.environment}-${key}", { stat = "Average" }],
              ["...", { stat = "Maximum" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "${key} - Duration"
            yAxis = {
              left = {
                min = 0
              }
            }
          }
          width  = 6
          height = 6
          x      = (index(keys(local.functions), key) % 4) * 6
          y      = floor(index(keys(local.functions), key) / 4) * 12 + 6
        }
      ]
    )
  })
}
