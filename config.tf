#######################################################################
# File: config.tf
#
# Description:
#   Terraform version constraints to ensure
#   compatibility and access to required resource types.
#
# Purpose:
#   Define minimum version requirements for reliable module execution
#   and access to AWS Managed Prometheus APIs.
#
#######################################################################

terraform {
  required_version = "1.12.2"
}