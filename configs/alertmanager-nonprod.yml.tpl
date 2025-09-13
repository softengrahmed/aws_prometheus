#######################################################################
# Enhanced Non-Production AlertManager Configuration
# Environment: ${environment}
# Region: ${region}
# Workspace: ${workspace_alias}
#######################################################################

global:
  smtp_smarthost: '${smtp_server}'
  smtp_from: 'dev-alerts-${environment}@company.com'
  smtp_hello: 'alertmanager-${environment}'
  smtp_require_tls: false  # Relaxed for development
  resolve_timeout: 10m     # Longer resolve time for dev
  %{~ if smtp_username != "" ~}
  smtp_auth_username: '${smtp_username}'
  smtp_auth_password: '${smtp_password}'
  %{~ endif ~}

route:
  group_by: ['alertname', 'service']
  group_wait: 30s          # Longer wait for dev
  group_interval: 1m       # Less frequent grouping
  repeat_interval: 4h      # Less frequent repeats
  receiver: 'dev-default'
  routes:
  # Critical alerts still get attention in dev
  - receiver: 'dev-critical'
    group_wait: 1m
    repeat_interval: 2h
    match:
      severity: critical

  # Warnings are grouped more heavily
  - receiver: 'dev-warnings'
    group_wait: 5m
    repeat_interval: 8h
    match:
      severity: warning

  # Testing and experimental alerts
  - receiver: 'dev-testing'
    group_wait: 10m
    repeat_interval: 24h
    match:
      environment: testing

receivers:
# Default development receiver
- name: 'dev-default'
  email_configs:
  - to: '${notification_email}'
    subject: '[${environment}] {{ .GroupLabels.alertname }}'
    body: |
      Development Environment Alert
      Environment: ${environment}
      Region: ${region}
      Workspace: ${workspace_alias}
      
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Instance: {{ .Labels.instance }}
      {{ end }}
      
      Note: This is a development environment alert.

# Critical alerts in development
- name: 'dev-critical'
  %{~ if slack_webhook_url != "" ~}
  slack_configs:
  - api_url: '${slack_webhook_url}'
    channel: '#dev-alerts'
    username: 'DevAlertManager'
    icon_emoji: ':construction:'
    title: ':orange_circle: DEV CRITICAL - ${environment}'
    text: |
      *Development Critical Alert*
      *Environment:* ${environment}
      *Region:* ${region}
      
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Service:* {{ .Labels.service }}
      {{ end }}
      
      _This is a development environment._
    send_resolved: true
  %{~ endif ~}
  email_configs:
  - to: '${notification_email}'
    subject: '[DEV-CRITICAL] ${environment} - {{ .GroupLabels.alertname }}'
    body: |
      DEVELOPMENT CRITICAL ALERT
      
      Environment: ${environment}
      Region: ${region}
      
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Service: {{ .Labels.service }}
      {{ end }}

# Warning alerts in development
- name: 'dev-warnings'
  %{~ if slack_webhook_url != "" ~}
  slack_configs:
  - api_url: '${slack_webhook_url}'
    channel: '#dev-alerts'
    username: 'DevAlertManager'
    icon_emoji: ':warning:'
    title: ':yellow_circle: DEV WARNING - ${environment}'
    text: |
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Environment:* ${environment}
      {{ end }}
  %{~ endif ~}

# Testing alerts - minimal notification
- name: 'dev-testing'
  email_configs:
  - to: '${notification_email}'
    subject: '[TEST] ${environment} - Testing Alerts'
    body: |
      Testing Environment Alerts - ${environment}
      
      {{ range .Alerts }}
      - {{ .Annotations.summary }}
      {{ end }}
      
      These are test alerts and can typically be ignored.

# Simplified inhibition for development
inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'service']