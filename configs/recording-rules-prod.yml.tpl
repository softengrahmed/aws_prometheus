#######################################################################
# Enhanced Production Recording Rules Configuration
# Environment: ${environment}
# Region: ${region}
# Workspace: ${workspace_alias}
# Scrape Interval: ${scrape_interval}
#######################################################################

groups:
# High-frequency SLI calculations (every 30s)
- name: sli_calculations_${environment}
  interval: 30s
  rules:
  # HTTP Request SLIs
  - record: sli:http_request_rate_5m
    expr: |
      sum(rate(http_requests_total[5m])) by (service, method, environment, region)
    labels:
      environment: ${environment}
      region: ${region}
      workspace: ${workspace_alias}

  - record: sli:http_error_rate_5m
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m])) by (service, method, environment, region) /
      sum(rate(http_requests_total[5m])) by (service, method, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: sli:http_latency_p95_5m
    expr: |
      histogram_quantile(0.95,
        sum(rate(http_request_duration_seconds_bucket[5m])) by (service, method, le, environment, region)
      )
    labels:
      environment: ${environment}
      region: ${region}

  - record: sli:http_latency_p99_5m
    expr: |
      histogram_quantile(0.99,
        sum(rate(http_request_duration_seconds_bucket[5m])) by (service, method, le, environment, region)
      )
    labels:
      environment: ${environment}
      region: ${region}

# Infrastructure SLIs
- name: infrastructure_slis_${environment}
  interval: 30s
  rules:
  # Node-level metrics
  - record: sli:node_cpu_utilization_5m
    expr: |
      100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance, environment, region) * 100)
    labels:
      environment: ${environment}
      region: ${region}

  - record: sli:node_memory_utilization_5m
    expr: |
      100 * (1 - ((node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes)))
    labels:
      environment: ${environment}
      region: ${region}

  - record: sli:node_disk_utilization_5m
    expr: |
      100 * (1 - ((node_filesystem_avail_bytes{fstype!="tmpfs"}) / (node_filesystem_size_bytes{fstype!="tmpfs"})))
    labels:
      environment: ${environment}
      region: ${region}

  # Kubernetes metrics
  - record: sli:pod_cpu_utilization_5m
    expr: |
      sum(rate(container_cpu_usage_seconds_total{container!="POD",container!=""}[5m])) by (pod, namespace, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: sli:pod_memory_utilization_5m
    expr: |
      sum(container_memory_working_set_bytes{container!="POD",container!=""}) by (pod, namespace, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

# Database SLIs
- name: database_slis_${environment}
  interval: 30s
  rules:
  - record: sli:db_connection_utilization_5m
    expr: |
      sum(mysql_global_status_threads_connected) by (instance, environment, region) /
      sum(mysql_global_variables_max_connections) by (instance, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: sli:db_query_rate_5m
    expr: |
      sum(rate(mysql_global_status_queries[5m])) by (instance, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  - record: sli:db_slow_query_rate_5m
    expr: |
      sum(rate(mysql_global_status_slow_queries[5m])) by (instance, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

# Business Logic SLIs (every 1m)
- name: business_slis_${environment}
  interval: 1m
  rules:
  # API endpoint success rates
  - record: sli:api_success_rate_10m
    expr: |
      sum(rate(api_requests_total{status="200"}[10m])) by (endpoint, service, environment, region) /
      sum(rate(api_requests_total[10m])) by (endpoint, service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  # Transaction rates
  - record: sli:transaction_rate_10m
    expr: |
      sum(rate(business_transactions_total[10m])) by (type, service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

  # Payment processing metrics
  - record: sli:payment_success_rate_10m
    expr: |
      sum(rate(payments_total{status="success"}[10m])) by (gateway, environment, region) /
      sum(rate(payments_total[10m])) by (gateway, environment, region)
    labels:
      environment: ${environment}
      region: ${region}

# SLO Aggregations (every 2m)
- name: slo_aggregations_${environment}
  interval: 2m
  rules:
  # Service-level SLO calculations
  - record: slo:service_availability_1h
    expr: |
      avg_over_time(sli:http_request_rate_5m[1h]) > bool 0
    labels:
      environment: ${environment}
      region: ${region}

  - record: slo:service_error_budget_1h
    expr: |
      1 - avg_over_time(sli:http_error_rate_5m[1h])
    labels:
      environment: ${environment}
      region: ${region}

  - record: slo:service_latency_budget_1h
    expr: |
      (sli:http_latency_p95_5m < bool 0.5) * 100
    labels:
      environment: ${environment}
      region: ${region}

# Multi-window SLO burn rates
- name: slo_burn_rates_${environment}
  interval: 1m
  rules:
  # Fast burn rate (5m)
  - record: slo:error_rate_burn_fast
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m])) by (service, environment, region) /
      sum(rate(http_requests_total[5m])) by (service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}
      burn_rate: fast

  # Medium burn rate (1h)
  - record: slo:error_rate_burn_medium
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[1h])) by (service, environment, region) /
      sum(rate(http_requests_total[1h])) by (service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}
      burn_rate: medium

  # Slow burn rate (6h)
  - record: slo:error_rate_burn_slow
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[6h])) by (service, environment, region) /
      sum(rate(http_requests_total[6h])) by (service, environment, region)
    labels:
      environment: ${environment}
      region: ${region}
      burn_rate: slow

# Cost optimization metrics (every 5m)
- name: cost_metrics_${environment}
  interval: 5m
  rules:
  - record: cost:cpu_cost_per_hour
    expr: |
      sum(kube_node_status_allocatable{resource="cpu"}) by (node, environment, region) * 0.05
    labels:
      environment: ${environment}
      region: ${region}

  - record: cost:memory_cost_per_hour
    expr: |
      sum(kube_node_status_allocatable{resource="memory"}) by (node, environment, region) / (1024*1024*1024) * 0.01
    labels:
      environment: ${environment}
      region: ${region}

# Regional aggregations (every 5m)
- name: regional_aggregations_${environment}
  interval: 5m
  rules:
  - record: region:total_requests_5m
    expr: |
      sum(sli:http_request_rate_5m) by (region, environment)
    labels:
      environment: ${environment}

  - record: region:avg_latency_5m
    expr: |
      avg(sli:http_latency_p95_5m) by (region, environment)
    labels:
      environment: ${environment}

  - record: region:error_rate_5m
    expr: |
      avg(sli:http_error_rate_5m) by (region, environment)
    labels:
      environment: ${environment}