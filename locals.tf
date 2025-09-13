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
#     * Production: Uses configs/alertmanager-prod.yml.tpl and recording-rules-prod.yml.tpl
#     * Non-production: Uses configs/alertmanager-nonprod.yml.tpl and recording-rules-nonprod.yml.tpl
#   - Cross-account principal generation based on allowed_source_accounts list
#   - Dynamic role naming with workspace alias for uniqueness
#   - Template variable substitution for environment and region context
#   - Final configuration merging with user-provided vs default templates
#######################################################################

locals {
  # Common tags applied to all resources
  common_tags = merge(
    {
      Environment      = var.environment
      Service          = "prometheus"
      ManagedBy        = "terraform"
      Module           = "amp-module"
      WorkspaceAlias   = var.workspace_alias
      ScrapeInterval   = var.scrape_interval
      HighAvailability = var.enable_high_availability
    },
    var.tags
  )

  # Current region if not provided
  current_region = var.region
}


locals {

  # Template variables for AlertManager configuration
  alertmanager_template_vars = {
    environment           = var.environment
    region                = local.current_region
    slack_webhook_url     = var.slack_webhook_url
    pagerduty_service_key = var.pagerduty_service_key
    notification_email    = var.notification_email
    smtp_server           = var.smtp_server
    workspace_alias       = var.workspace_alias
    scrape_interval       = var.scrape_interval
    smtp_username         = var.smtp_username
    smtp_password         = var.smtp_password
    teams_webhook_url     = var.teams_webhook_url
  }

  # Default alert manager configuration
  default_alertmanager_config = var.environment == "production" ? templatefile("${path.module}/configs/alertmanager-prod.yml.tpl", local.alertmanager_template_vars) : templatefile("${path.module}/configs/alertmanager-nonprod.yml.tpl", local.alertmanager_template_vars)

  # Default recording rule configuration
  default_recording_rules_config = var.environment == "production" ? templatefile("${path.module}/configs/recording-rules-prod.yml.tpl", local.alertmanager_template_vars) : templatefile("${path.module}/configs/recording-rules-nonprod.yml.tpl", local.alertmanager_template_vars)

  final_alertmanager_config    = var.alertmanager_config != "" ? var.alertmanager_config : (var.create_default_rules ? local.default_alertmanager_config : "")
  final_recording_rules_config = var.recording_rules_config != "" ? var.recording_rules_config : (var.create_default_rules ? local.default_recording_rules_config : "")

}

