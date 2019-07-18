# Prometheus
global:
  scrape_interval: ${var.prometheus_scrape_interval} # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: ${var.prometheus_evaluation_interval} # Evaluate rules every 15 seconds. The default is every 1 minute.
  scrape_timeout: ${var.prometheus_evaluation_interval} # How long until a scrape request times out. Default 10s
  external_labels:
    project: ${var.project_name}
    platform: shepherdcloud

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
        - localhost:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - /etc/prometheus/rules/*.rules

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']