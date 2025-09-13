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
#   - Critical for ADOT Integration:
#     * remote_write_url: ADOT collectors use this for metrics ingestion
#     * workspace_endpoint: Base URL for Prometheus API access
#   - Grafana Integration:
#     * workspace_arn: Used as data source in AWS Managed Grafana
#     * query_url: Direct query endpoint for dashboard configuration
#   - All outputs include workspace identification for multi-instance deployments
#######################################################################

# Temporary debug output
output "debug_paths" {
  value = {
    module_path = path.module
    root_path   = path.root
    cwd_path    = path.cwd
  }
}
output "kms_key_id" {
  description = "ID of the Prometheus kms key"
  value       = aws_kms_key.jnj_amp.id
}

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
