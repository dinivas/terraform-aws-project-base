# Prometheus
global:
  scrape_interval: ${prometheus_scrape_interval} # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: ${prometheus_evaluation_interval} # Evaluate rules every 15 seconds. The default is every 1 minute.
  scrape_timeout: ${prometheus_scrape_timeout} # How long until a scrape request times out. Default 10s
  external_labels:
    project: ${project_name}
    platform: dinivas

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

  - job_name: consul
    consul_sd_configs:
      - server: 'localhost:8500'
    relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: .*,monitor,.*
        action: keep
      - source_labels: [__meta_consul_service]
        target_label: service