# kms key configuratino
resource "aws_kms_key" "jnj_amp" {
  description             = "AWS managed key to encrypt amp contents"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  tags = local.common_tags
}

# KMS alias for easier reference
resource "aws_kms_alias" "jnj_amp" {
  name          = "alias/prometheus-${var.environment}-${var.workspace_alias}"
  target_key_id = aws_kms_key.jnj_amp.key_id
}

# KMS key for SMTP password encryption (separate from AMP key for better security separation)
resource "aws_kms_key" "smtp_credentials" {
  description             = "KMS key for encrypting SMTP credentials"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name    = "prometheus-smtp-credentials-${var.environment}"
    Purpose = "SMTP password encryption"
  })
}

# Separate resource for the key policy to avoid circular dependency
resource "aws_kms_key_policy" "smtp_credentials" {
  key_id = aws_kms_key.smtp_credentials.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = aws_kms_key.smtp_credentials.arn
      },
      {
        Sid    = "Allow Terraform execution role to use the key"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.smtp_credentials.arn
        Condition = {
          StringEquals = {
            "kms:EncryptionContext:service"     = "prometheus-alertmanager"
            "kms:EncryptionContext:environment" = var.environment
          }
        }
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key for log encryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.smtp_credentials.arn
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/prometheus/*"
          }
        }
      }
    ]
  })
}

# KMS alias for SMTP credentials key
resource "aws_kms_alias" "smtp_credentials" {
  name          = "alias/prometheus-smtp-${var.environment}-${var.workspace_alias}"
  target_key_id = aws_kms_key.smtp_credentials.key_id
}