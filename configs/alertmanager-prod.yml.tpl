#######################################################################
# Enhanced Production AlertManager Configuration
# Environment: ${environment}
# Region: ${region}
# Workspace: ${workspace_alias}
#######################################################################

global:
  smtp_smarthost: '${smtp_server}'
  smtp_from: '${notification_email}'
  smtp_hello: 'alertmanager-${environment}-${region}'
  smtp_require_tls: true
  resolve_timeout: 5m
  %{~ if smtp_username != "" ~}
  smtp_auth_username: '${smtp_username}'
  smtp_auth_password: '${smtp_password}'
  %{~ endif ~}

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  group_by: ['alertname', 'cluster', 'service', 'region']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default-receiver'
  routes:
  # Critical alerts - immediate escalation
  - receiver: 'critical-alerts'
    group_wait: 5s
    repeat_interval: 30m
    match:
      severity: critical
    routes:
    # Database critical alerts - special handling
    - receiver: 'database-critical'
      match:
        service: database
        severity: critical
    # Infrastructure critical alerts
    - receiver: 'infrastructure-critical'
      match_re:
        service: 'node|kubernetes|infrastructure'
        severity: critical

  # Warning alerts - standard timing
  - receiver: 'warning-alerts'
    group_wait: 2m
    repeat_interval: 6h
    match:
      severity: warning

  # Info alerts - daily digest
  - receiver: 'info-alerts'
    group_wait: 5m
    repeat_interval: 24h
    match:
      severity: info

  # Security alerts - immediate attention
  - receiver: 'security-alerts'
    group_wait: 0s
    repeat_interval: 15m
    match_re:
      alertname: 'Security.*|Auth.*|Intrusion.*'

receivers:
# Default catch-all receiver
- name: 'default-receiver'
  email_configs:
  - to: '${notification_email}'
    subject: '[${environment}] {{ .GroupLabels.alertname }} - {{ .Status | toUpper }}'
    body: |
      Environment: ${environment}
      Region: ${region}
      Workspace: ${workspace_alias}
      
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
      {{ end }}

# Critical alerts - multi-channel notification
- name: 'critical-alerts'
  %{~ if slack_webhook_url != "" ~}
  slack_configs:
  - api_url: '${slack_webhook_url}'
    channel: '#critical-alerts'
    username: 'AlertManager-${environment}'
    icon_emoji: ':fire:'
    title: ':rotating_light: CRITICAL ALERT - ${environment} (${region})'
    text: |
      *Environment:* ${environment}
      *Region:* ${region}
      *Workspace:* ${workspace_alias}
      
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Description:* {{ .Annotations.description }}
      *Severity:* {{ .Labels.severity }}
      *Service:* {{ .Labels.service }}
      *Instance:* {{ .Labels.instance }}
      {{ if .Annotations.runbook_url }}*Runbook:* {{ .Annotations.runbook_url }}{{ end }}
      {{ end }}
    send_resolved: true
    title_link: 'https://grafana.company.com/alerting/list'
    actions:
    - type: button
      text: 'View in Grafana'
      url: 'https://grafana.company.com/alerting/list'
    - type: button
      text: 'Acknowledge'
      url: 'https://alertmanager.company.com/#/alerts'
  %{~ endif ~}
  %{~ if pagerduty_service_key != "" ~}
  pagerduty_configs:
  - service_key: '${pagerduty_service_key}'
    description: 'Critical alert in ${environment} (${region})'
    severity: 'critical'
    details:
      environment: '${environment}'
      region: '${region}'
      workspace: '${workspace_alias}'
      firing_alerts: '{{ .Alerts.Firing | len }}'
      resolved_alerts: '{{ .Alerts.Resolved | len }}'
    links:
    - href: 'https://grafana.company.com/alerting/list'
      text: 'View in Grafana'
  %{~ endif ~}
  %{~ if teams_webhook_url != "" ~}
  webhook_configs:
  - url: '${teams_webhook_url}'
    send_resolved: true
    http_config:
      bearer_token: 'teams-webhook-token'
    title: 'Critical Alert - ${environment}'
    text: |
      {{ range .Alerts }}
      **{{ .Annotations.summary }}**
      Description: {{ .Annotations.description }}
      Environment: ${environment}
      Region: ${region}
      {{ end }}
  %{~ endif ~}
  email_configs:
  - to: '${notification_email}'
    subject: '[CRITICAL] ${environment} - {{ .GroupLabels.alertname }}'
    headers:
      Priority: 'urgent'
      X-Environment: '${environment}'
    html: |
      <h2 style="color: red;">🚨 CRITICAL ALERT - ${environment}</h2>
      <p><strong>Environment:</strong> ${environment}</p>
      <p><strong>Region:</strong> ${region}</p>
      <p><strong>Workspace:</strong> ${workspace_alias}</p>
      {{ range .Alerts }}
      <div style="border: 2px solid red; padding: 10px; margin: 10px 0;">
        <h3>{{ .Annotations.summary }}</h3>
        <p><strong>Description:</strong> {{ .Annotations.description }}</p>
        <p><strong>Severity:</strong> {{ .Labels.severity }}</p>
        <p><strong>Service:</strong> {{ .Labels.service }}</p>
        <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
        {{ if .Annotations.runbook_url }}
        <p><strong>Runbook:</strong> <a href="{{ .Annotations.runbook_url }}">{{ .Annotations.runbook_url }}</a></p>
        {{ end }}
      </div>
      {{ end }}

# Database critical alerts
- name: 'database-critical'
  %{~ if slack_webhook_url != "" ~}
  slack_configs:
  - api_url: '${slack_webhook_url}'
    channel: '#database-alerts'
    username: 'DB-AlertManager'
    icon_emoji: ':database:'
    title: ':warning: DATABASE CRITICAL - ${environment}'
    text: |
      *Database Emergency - Immediate Action Required*
      *Environment:* ${environment}
      *Region:* ${region}
      
      {{ range .Alerts }}
      *Database:* {{ .Labels.database }}
      *Issue:* {{ .Annotations.summary }}
      *Details:* {{ .Annotations.description }}
      {{ end }}
  %{~ endif ~}
  email_configs:
  - to: 'dba-team@company.com,${notification_email}'
    subject: '[DB-CRITICAL] ${environment} Database Emergency'

# Infrastructure critical alerts
- name: 'infrastructure-critical'
  %{~ if slack_webhook_url != "" ~}
  slack_configs:
  - api_url: '${slack_webhook_url}'
    channel: '#infrastructure-alerts'
    username: 'Infra-AlertManager'
    icon_emoji: ':gear:'
    title: ':exclamation: INFRASTRUCTURE CRITICAL - ${environment}'
  %{~ endif ~}
  email_configs:
  - to: 'infrastructure-team@company.com,${notification_email}'
    subject: '[INFRA-CRITICAL] ${environment} Infrastructure Issue'

# Warning alerts
- name: 'warning-alerts'
  %{~ if slack_webhook_url != "" ~}
  slack_configs:
  - api_url: '${slack_webhook_url}'
    channel: '#warning-alerts'
    username: 'AlertManager-${environment}'
    icon_emoji: ':warning:'
    title: ':yellow_circle: WARNING - ${environment} (${region})'
    text: |
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Environment:* ${environment}
      *Service:* {{ .Labels.service }}
      {{ end }}
    send_resolved: true
  %{~ endif ~}
  email_configs:
  - to: '${notification_email}'
    subject: '[WARNING] ${environment} - {{ .GroupLabels.alertname }}'

# Info alerts - daily digest
- name: 'info-alerts'
  email_configs:
  - to: '${notification_email}'
    subject: '[INFO] ${environment} Daily Alert Digest'
    body: |
      Daily Alert Summary for ${environment} (${region})
      
      {{ range .Alerts }}
      - {{ .Annotations.summary }}
      {{ end }}

# Security alerts
- name: 'security-alerts'
  %{~ if slack_webhook_url != "" ~}
  slack_configs:
  - api_url: '${slack_webhook_url}'
    channel: '#security-alerts'
    username: 'Security-AlertManager'
    icon_emoji: ':shield:'
    title: ':red_circle: SECURITY ALERT - ${environment}'
    color: 'danger'
  %{~ endif ~}
  %{~ if pagerduty_service_key != "" ~}
  pagerduty_configs:
  - service_key: '${pagerduty_service_key}'
    description: 'Security incident in ${environment}'
    severity: 'critical'
    class: 'security'
  %{~ endif ~}
  email_configs:
  - to: 'security-team@company.com,${notification_email}'
    subject: '[SECURITY] ${environment} Security Alert'
    headers:
      Priority: 'urgent'
      X-Alert-Type: 'security'

# Inhibition rules to reduce alert noise
inhibit_rules:
# Critical alerts suppress warnings for the same service
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'cluster', 'service']

# Infrastructure down suppresses service alerts
- source_match:
    alertname: 'NodeDown'
  target_match_re:
    service: '.*'
  equal: ['instance']

# Database down suppresses application alerts
- source_match:
    alertname: 'DatabaseDown'
  target_match_re:
    alertname: 'App.*'
  equal: ['cluster']