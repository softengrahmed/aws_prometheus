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
#   - No direct feature flags, but supports IRSA functionality
#   - EKS cluster data source loops through var.eks_cluster_names list
#   - OIDC issuer URLs extracted for each EKS cluster for IRSA trust policies
#   - When eks_cluster_names is empty: No EKS integration configured
#   - When eks_cluster_names populated: Enables ADOT collector IAM roles
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