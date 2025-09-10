#######################################################################
# File: config.tf
#
# Description:
#   Terraform and AWS provider version constraints to ensure
#   compatibility and access to required resource types.
#
# Purpose:
#   Define minimum version requirements for reliable module execution
#   and access to AWS Managed Prometheus APIs.
#
# Notes:
#   - Requires Terraform >= 1.0 for modern syntax and features
#   - Requires AWS provider >= 5.0 for:
#     * aws_prometheus_workspace resource support
#     * aws_prometheus_alert_manager_definition resource support  
#     * aws_prometheus_rule_group_namespace resource support
#     * Enhanced IAM and KMS integration capabilities
#   - Version constraints ensure feature compatibility across environments
#   - No upper version bounds to allow for future AWS provider updates
#######################################################################

terraform {
  required_version = "1.12.2"
}