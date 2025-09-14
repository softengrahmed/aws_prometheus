#######################################################################
# File: main.tf
#
# Description:
#   Core AWS Managed Prometheus workspace and associated components
#   including AlertManager and recording rules configuration.
#
# Purpose:
#   Deploy production-ready Prometheus workspace with optional alerting
#   and pre-computed metrics capabilities.
#
# Notes:
#   - Feature Flag: enable_alertmanager (default: true)
#     * When enabled: Deploys aws_prometheus_alert_manager_definition
#     * Enables smart alert routing, grouping, and escalation
#     * Requires alertmanager configuration to be present
#   - Feature Flag: enable_recording_rules (default: true)  
#     * When enabled: Deploys aws_prometheus_rule_group_namespace
#     * Creates pre-computed metrics for faster dashboard queries
#     * Enables automated SLI/SLO calculations
#   - Conditional behavior: Resources only deploy when both feature flag
#     is enabled AND configuration content exists
#   - Feature Flag: logging_configuration.log_group_arn
#     * When null: Creates new CloudWatch log group for AMP logs
#     * When provided: Uses existing log group for operational logging
#######################################################################

# Prometheus workspace
resource "aws_prometheus_workspace" "main" {
  alias       = var.workspace_alias
  kms_key_arn = aws_kms_key.jnj_amp.arn

  dynamic "logging_configuration" {
    for_each = var.logging_configuration.log_group_arn != null ? [1] : []
    content {
      log_group_arn = var.logging_configuration.log_group_arn
    }
  }

  tags = merge(local.common_tags, {
    Name = var.workspace_alias
  })
}

# Alert Manager configuration
resource "aws_prometheus_alert_manager_definition" "main" {
  count = var.enable_alertmanager && local.final_alertmanager_config != "" ? 1 : 0

  workspace_id = aws_prometheus_workspace.main.id
  definition   = local.final_alertmanager_config

  depends_on = [aws_prometheus_workspace.main]
}

# Recording rules configuration  
resource "aws_prometheus_rule_group_namespace" "main" {
  count = var.enable_recording_rules && local.final_recording_rules_config != "" ? 1 : 0

  workspace_id = aws_prometheus_workspace.main.id
  name         = "${var.environment}-rules"
  data         = local.default_recording_rules_config

  depends_on = [aws_prometheus_workspace.main]
}

