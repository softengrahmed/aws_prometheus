#######################################################################
# Enhanced Non-Production Recording Rules Configuration
# Environment: ${environment}
# Region: ${region}
# Workspace: ${workspace_alias}
# Scrape Interval: ${scrape_interval}
#######################################################################

groups:
# Basic SLI calculations for development (every 1m - less frequent)
- name: basic_slis_${environment}
  interval: 1m
  rules:
  # Simplified HTTP metrics
  - record: dev:http_request_rate_5m
    expr: |
      sum(rate(http_requests_total[5m])) by (service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}
      workspace: ${workspace_alias}

  - record: dev:http_error_rate_5m
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m])) by (service, environment, region) /
      sum(rate(http_requests_total[5m])) by (service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:http_latency_p95_5m
    expr: |
      histogram_quantile(0.95,
        sum(rate(http_request_duration_seconds_bucket[5m])) by (service, le, environment, region)
      )
    labels:
      environment: ${environment}
      region: ${region}

# Infrastructure basics (every 2m)
- name: basic_infrastructure_${environment}
  interval: 2m
  rules:
  # Simplified node metrics
  - record: dev:node_cpu_avg_5m
    expr: |
      100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance, environment) * 100)
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:node_memory_used_percent
    expr: |
      100 * (1 - ((node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes)))
    labels:
      environment: ${environment}
      region: ${region}

  # Pod metrics for development
  - record: dev:pod_count_by_namespace
    expr: |
      count(kube_pod_info) by (namespace, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:pod_restart_rate_5m
    expr: |
      rate(kube_pod_container_status_restarts_total[5m])
    labels:
      environment: ${environment}
      region: ${region}

# Development testing metrics (every 5m)
- name: development_metrics_${environment}
  interval: 5m
  rules:
  # Test execution metrics
  - record: dev:test_execution_rate_10m
    expr: |
      sum(rate(test_executions_total[10m])) by (test_suite, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:test_success_rate_10m
    expr: |
      sum(rate(test_executions_total{result="pass"}[10m])) by (test_suite, environment, region) /
      sum(rate(test_executions_total[10m])) by (test_suite, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  # Build metrics
  - record: dev:build_duration_avg_1h
    expr: |
      avg_over_time(build_duration_seconds[1h])
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:deployment_frequency_24h
    expr: |
      sum(increase(deployments_total[24h])) by (service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

# Resource utilization for cost monitoring (every 10m)
- name: dev_cost_tracking_${environment}
  interval: 10m
  rules:
  - record: dev:total_cpu_cores_used
    expr: |
      sum(rate(container_cpu_usage_seconds_total{container!="POD"}[5m])) by (environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:total_memory_used_gb
    expr: |
      sum(container_memory_working_set_bytes{container!="POD"}) by (environment, region) / (1024*1024*1024)
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:estimated_hourly_cost
    expr: |
      (dev:total_cpu_cores_used * 0.02) + (dev:total_memory_used_gb * 0.005)
    labels:
      environment: ${environment}
      region: ${region}

# Simplified alerting support (every 2m)
- name: dev_alerting_support_${environment}
  interval: 2m
  rules:
  # Service health check
  - record: dev:service_up
    expr: |
      up{job=~".*-service"}
    labels:
      environment: ${environment}
      region: ${region}

  # Database connection health
  - record: dev:db_connection_health
    expr: |
      mysql_up or postgres_up or redis_up
    labels:
      environment: ${environment}
      region: ${region}

  # API endpoint health
  - record: dev:api_health_score
    expr: |
      avg(dev:http_request_rate_5m > bool 0) by (service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

# Environment-specific aggregations (every 5m)
- name: dev_environment_overview_${environment}
  interval: 5m
  rules:
  - record: dev:total_services_running
    expr: |
      count(up == 1) by (environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:total_requests_per_minute
    expr: |
      sum(dev:http_request_rate_5m) by (environment, region) * 60
    labels:
      environment: ${environment}
      region: ${region}

  - record: dev:avg_response_time_ms
    expr: |
      avg(dev:http_latency_p95_5m) by (environment, region) * 1000
    labels:
      environment: ${environment}
      region: ${region}

# Development experiment tracking (every 10m)
- name: dev_experiments_${environment}
  interval: 10m
  rules:
  # Feature flag usage
  - record: dev:feature_flag_usage_1h
    expr: |
      sum(rate(feature_flag_evaluations_total[1h])) by (flag_name, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  # A/B test metrics
  - record: dev:ab_test_conversion_rate_1h
    expr: |
      sum(rate(ab_test_conversions_total[1h])) by (test_name, variant, environment, region) /
      sum(rate(ab_test_exposures_total[1h])) by (test_name, variant, environment, region)
    labels:
      environment: ${environment}
      region: ${region}