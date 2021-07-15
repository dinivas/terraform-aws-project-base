-   content: |
        {"service":
            {"name": "${consul_cluster_name}-dashboard",
            "tags": ["web"],
            "port": 8500
            }
        }

    owner: consul:bin
    path: /etc/consul/consul.d/consul-dashboard-service.json
    permissions: '644'