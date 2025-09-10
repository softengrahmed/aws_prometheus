#######################################################################
# File: locals.tf
#
# Description:
#   Local value computations including conditional logic for feature flags,
#   template file processing, and environment-specific configurations.
#
# Purpose:
#   Centralize complex logic and provide computed values based on
#   input variables and feature flag states.
#
# Notes:
#   - Feature Flag Logic: create_default_rules
#     * When enabled: Loads templatefile() for alertmanager and recording rules
#     * Selects environment-specific templates (prod vs nonprod)
#     * When disabled: Uses empty configuration strings
#   - Feature Flag Logic: environment-based template selection
#     * Production: Uses configs/alertmanager-prod.yml and recording-rules-prod.yml
#     * Non-production: Uses configs/alertmanager-nonprod.yml and recording-rules-nonprod.yml
#   - Cross-account principal generation based on allowed_source_accounts list
#   - Dynamic role naming with workspace alias for uniqueness
#   - Template variable substitution for environment and region context
#   - Final configuration merging with user-provided vs default templates
#######################################################################

locals {
  # Common tags applied to all resources
  common_tags = merge(
    {
      Environment        = var.environment
      Service           = "prometheus"
      ManagedBy         = "terraform"
      Module            = "amp-module"
      WorkspaceAlias    = var.workspace_alias
      RetentionDays     = var.retention_period_days
      ScrapeInterval    = var.scrape_interval
      HighAvailability  = var.enable_high_availability
    },
    var.tags
  )

  # Current region if not provided
  current_region = var.region != "" ? var.region : data.aws_region.current.name

  # Default alert manager configuration
  default_alertmanager_config = var.environment == "production" ? templatefile("${path.module}/configs/alertmanager-prod.yml", {
    environment = var.environment
    region      = local.current_region
  }) : templatefile("${path.module}/configs/alertmanager-nonprod.yml", {
    environment = var.environment
    region      = local.current_region
  })

  # Default recording rules configuration
  default_recording_rules_config = var.environment == "production" ? templatefile("${path.module}/configs/recording-rules-prod.yml", {
    environment = var.environment
    region      = local.current_region
  }) : templatefile("${path.module}/configs/recording-rules-nonprod.yml", {
    environment = var.environment
    region      = local.current_region
  })

  # Final configurations
  final_alertmanager_config = var.alertmanager_config != "" ? var.alertmanager_config : (var.create_default_rules ? local.default_alertmanager_config : "")
  final_recording_rules_config = var.recording_rules_config != "" ? var.recording_rules_config : (var.create_default_rules ? local.default_recording_rules_config : "")

  # IAM role names
  workspace_role_name = "AMP-${var.workspace_alias}-ServiceRole"
  collector_role_name = "AMP-${var.workspace_alias}-CollectorRole"
  
  # Cross-account access principals
  cross_account_principals = [
    for account_id in var.allowed_source_accounts :
    "arn:aws:iam::${account_id}:root"
  ]
}
