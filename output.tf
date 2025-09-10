#######################################################################
# File: outputs.tf
#
# Description:
#   Module output values exposing workspace details, IAM role ARNs,
#   and endpoint URLs for integration with other systems.
#
# Purpose:
#   Provide essential information for ADOT configuration, Grafana
#   data source setup, and infrastructure automation.
#
# Notes:
#   - Feature Flag Dependent Outputs:
#     * alertmanager_enabled: Shows true when enable_alertmanager=true AND config exists
#     * recording_rules_enabled: Shows true when enable_recording_rules=true AND config exists
#     * log_group_arn: Points to created or provided log group based on logging_configuration
#   - Critical for ADOT Integration:
#     * collector_role_arn: Used for EKS service account annotations (IRSA)
#     * remote_write_url: ADOT collectors use this for metrics ingestion
#     * workspace_endpoint: Base URL for Prometheus API access
#   - Grafana Integration:
#     * workspace_arn: Used as data source in AWS Managed Grafana
#     * query_url: Direct query endpoint for dashboard configuration
#   - All outputs include workspace identification for multi-instance deployments
#######################################################################

output "workspace_id" {
  description = "ID of the Prometheus workspace"
  value       = aws_prometheus_workspace.main.id
}

output "workspace_arn" {
  description = "ARN of the Prometheus workspace"
  value       = aws_prometheus_workspace.main.arn
}

output "workspace_endpoint" {
  description = "Prometheus workspace endpoint URL"
  value       = aws_prometheus_workspace.main.prometheus_endpoint
}

output "workspace_alias" {
  description = "Alias of the Prometheus workspace"
  value       = aws_prometheus_workspace.main.alias
}

output "remote_write_url" {
  description = "Remote write URL for the Prometheus workspace"
  value       = "${aws_prometheus_workspace.main.prometheus_endpoint}api/v1/remote_write"
}

output "query_url" {
  description = "Query URL for the Prometheus workspace"
  value       = "${aws_prometheus_workspace.main.prometheus_endpoint}api/v1/query"
}

output "workspace_role_arn" {
  description = "ARN of the Prometheus workspace IAM role"
  value       = aws_iam_role.prometheus_workspace_role.arn
}

output "collector_role_arn" {
  description = "ARN of the ADOT collector IAM role"
  value       = aws_iam_role.adot_collector_role.arn
}

output "collector_role_name" {
  description = "Name of the ADOT collector IAM role"
  value       = aws_iam_role.adot_collector_role.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.prometheus_logs[0].name, var.logging_configuration.log_group_arn)
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.prometheus_logs[0].arn, var.logging_configuration.log_group_arn)
}

output "alertmanager_enabled" {
  description = "Whether Alert Manager is enabled"
  value       = var.enable_alertmanager && local.final_alertmanager_config != ""
}

output "recording_rules_enabled" {
  description = "Whether recording rules are enabled"
  value       = var.enable_recording_rules && local.final_recording_rules_config != ""
}