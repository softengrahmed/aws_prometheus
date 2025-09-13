#######################################################################
# File: variables.tf
#
# Description:
#   Input variable definitions for AWS Managed Prometheus module
#   with validation rules and feature flag controls.
#
# Purpose:
#   Define configurable parameters for AMP workspace deployment
#   with environment-specific and feature-based customization.
#
# Notes:
#   - Feature Flag: enable_alertmanager (bool, default: true)
#     * Controls deployment of AlertManager component
#     * When disabled: No alerting capabilities, results in cost reduction
#   - Feature Flag: enable_recording_rules (bool, default: true)
#     * Controls deployment of recording rules namespace
#     * When disabled: No pre-computed metrics, results in  slower queries
#   - Feature Flag: enable_high_availability (bool, default: false)
#     * When enabled: Configures HA settings and resource sizing
#     * Affects tagging and operational configurations
#   - Feature Flag: create_default_rules (bool, default: true)
#     * When enabled: Loads environment-specific template configurations
#     * When disabled: Requires custom configuration input
#   - Validation: Environment must be production|staging|development|testing|nonprod
#   - Validation: Scrape interval must match format [0-9]+[smh]
#   - Validation: Retention period must be 1-450 days
#######################################################################

variable "workspace_alias" {
  description = "Alias for the Prometheus workspace"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.workspace_alias))
    error_message = "Workspace alias must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  validation {
    condition     = contains(["production", "staging", "development", "testing", "nonprod"], var.environment)
    error_message = "Environment must be one of: production, staging, development, testing, nonprod."
  }
}

variable "region" {
  description = "AWS region for the Prometheus workspace"
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_alertmanager" {
  description = "Enable Alert Manager for the workspace"
  type        = bool
  default     = true
}

variable "alertmanager_config" {
  description = "Alert Manager configuration in YAML format"
  type        = string
  default     = ""
}

variable "enable_recording_rules" {
  description = "Enable recording rules for the workspace"
  type        = bool
  default     = true
}

variable "recording_rules_config" {
  description = "Recording rules configuration in YAML format"
  type        = string
  default     = ""
}

variable "create_default_rules" {
  description = "Create default recording and alerting rules"
  type        = bool
  default     = true
}

variable "eks_cluster_names" {
  description = "List of EKS cluster names for IRSA setup"
  type        = list(string)
  default     = []
}



variable "scrape_interval" {
  description = "Default scrape interval for metrics collection"
  type        = string
  default     = "30s"
  validation {
    condition     = can(regex("^[0-9]+[smh]$", var.scrape_interval))
    error_message = "Scrape interval must be in format like '30s', '1m', '5m', etc."
  }
}

variable "enable_high_availability" {
  description = "Enable high availability features"
  type        = bool
  default     = false
}

# alert-manager template variables
variable "slack_webhook_url" {
  description = "Slack webhook URL for alert notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_service_key" {
  description = "PagerDuty service integration key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "alerts@company.com"
}

variable "smtp_server" {
  description = "SMTP server for email notifications"
  type        = string
  default     = "localhost:587"
}

variable "smtp_username" {
  description = "User name for smtp"
  type        = string
  default     = "admin"
}


variable "teams_webhook_url" {
  description = "webhook url"
  type        = string
  default     = "https://localhost"
}

variable "smtp_password" {
  description = "User name for smtp"
  type        = string
  default     = "@!@!@!"
  sensitive   = true
}

variable "deletion_window_in_days" {
  description = "kms rotation window"
  type        = number
  default     = "7"
}

variable "logging_configuration" {
  description = "Logging configuration for the workspace"
  type = object({
    log_group_arn = optional(string)
  })
  default = {}
}
