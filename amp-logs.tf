# CloudWatch log group for Prometheus (if logging enabled)
resource "aws_cloudwatch_log_group" "prometheus_logs" {
  count = var.logging_configuration.log_group_arn == null ? 1 : 0

  name              = "/aws/prometheus/${var.workspace_alias}"
  retention_in_days = var.environment == "production" ? 365 : 7
  kms_key_id        = aws_kms_key.jnj_amp.id

  tags = merge(local.common_tags, {
    Name = "/aws/prometheus/${var.workspace_alias}"
    Type = "PrometheusLogs"
  })
}