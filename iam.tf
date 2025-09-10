#######################################################################
# File: iam.tf
#
# Description:
#   IAM roles, policies, and cross-account access controls for
#   Prometheus workspace and ADOT collector integration.
#
# Purpose:
#   Establish secure access patterns for AMP workspace operations
#   and enable IRSA-based authentication for EKS workloads.
#
# Notes:
#   - Feature Flag: enable_cross_region_access (default: false)
#     * When enabled: Creates aws_iam_policy.cross_account_access
#     * Enables multi-region and cross-account workspace access
#     * Requires allowed_source_accounts list to be populated
#   - Feature Flag: eks_cluster_names list
#     * When populated: Creates IRSA trust relationships for each cluster
#     * Enables ADOT collectors to assume IAM roles via service accounts
#     * Generates unique OIDC-based trust policies per cluster
#   - Feature Flag: kms_key_id (optional)
#     * When provided: Adds KMS permissions to workspace role
#     * Enables encryption/decryption for AMP data at rest
#   - Automatic policy attachments based on AWS managed policies
#   - Service-linked role creation for AMP workspace operations
#   - ADOT collector role supports both EC2 and EKS (IRSA) usage patterns
#######################################################################


# IAM role for Prometheus workspace
resource "aws_iam_role" "prometheus_workspace_role" {
  name = local.workspace_role_name
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "aps.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = local.workspace_role_name
    Type = "WorkspaceRole"
  })
}

# Attach AWS managed policy for Prometheus service
resource "aws_iam_role_policy_attachment" "prometheus_service_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  role       = aws_iam_role.prometheus_workspace_role.name
}

resource "aws_iam_role_policy_attachment" "prometheus_query_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonPrometheusQueryAccess"
  role       = aws_iam_role.prometheus_workspace_role.name
}

# Custom policy for additional permissions
resource "aws_iam_role_policy" "prometheus_additional_permissions" {
  name = "AdditionalPrometheusPermissions"
  role = aws_iam_role.prometheus_workspace_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_id != null ? [var.kms_key_id] : []
        Condition = var.kms_key_id != null ? {
          StringEquals = {
            "kms:ViaService" = "aps.${local.current_region}.amazonaws.com"
          }
        } : null
      }
    ]
  })
}

# IAM role for ADOT collectors (IRSA)
resource "aws_iam_role" "adot_collector_role" {
  name = local.collector_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ], [
      for cluster_name, cluster_data in data.aws_eks_cluster.clusters : {
        Effect = "Allow"
        Principal = {
          Federated = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(cluster_data.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(cluster_data.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:adot-collector"
            "${replace(cluster_data.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ])
  })

  tags = merge(local.common_tags, {
    Name = local.collector_role_name
    Type = "CollectorRole"
  })
}

# Policy for ADOT collector to write to Prometheus
resource "aws_iam_policy" "adot_prometheus_policy" {
  name        = "AMP-${var.workspace_alias}-ADOTCollectorPolicy"
  description = "Policy for ADOT collector to write to AMP workspace"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata",
          "aps:QueryMetrics"
        ]
        Resource = aws_prometheus_workspace.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "aps:ListWorkspaces"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "adot_prometheus_policy_attachment" {
  policy_arn = aws_iam_policy.adot_prometheus_policy.arn
  role       = aws_iam_role.adot_collector_role.name
}

# Cross-account access policy (if enabled)
resource "aws_iam_policy" "cross_account_access" {
  count = var.enable_cross_region_access && length(var.allowed_source_accounts) > 0 ? 1 : 0
  
  name        = "AMP-${var.workspace_alias}-CrossAccountAccess"
  description = "Cross-account access policy for AMP workspace"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = local.cross_account_principals
        }
        Action = [
          "aps:RemoteWrite",
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.main.arn
      }
    ]
  })

  tags = local.common_tags
}
