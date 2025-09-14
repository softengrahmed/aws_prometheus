#######################################################################
# File: data.tf
#
# Description:
#   Data source queries for AWS account information, region details,
#   and EKS cluster OIDC configuration for IRSA setup.
#
# Purpose:
#   Retrieve dynamic AWS environment information needed for IAM
#   trust relationships and cross-service integration.
#
# Notes:
#   - Supports multi-cluster environments with unique OIDC per cluster
#   - Current account, region, and partition data used throughout module
#######################################################################

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

# Get EKS cluster OIDC issuer URLs for IRSA setup
data "aws_eks_cluster" "clusters" {
  for_each = toset(var.eks_cluster_names)
  name     = each.value
}

# Decrypt SMTP password from KMS
# The encrypted password should be stored as a base64-encoded ciphertext blob
data "aws_kms_secrets" "smtp_credentials" {
  count = var.smtp_password_encrypted != "" ? 1 : 0

  secret {
    name    = "smtp_password"
    payload = var.smtp_password_encrypted

    # Use the dedicated SMTP credentials KMS key
    context = {
      service     = "prometheus-alertmanager"
      environment = var.environment
    }
  }
}