#cloud-config
# vim: syntax=yaml

final_message: "Dinivas consul is ready after $UPTIME seconds, Happy DINIVAS!!!"
runcmd:
  - [ sh, -c, /etc/configure-consul.sh]
write_files:
-   content: |
        {
          "addresses": {
              "dns": "0.0.0.0",
              "grpc": "0.0.0.0",
              "http": "0.0.0.0",
              "https": "0.0.0.0"
          },
          "advertise_addr": "",
          "advertise_addr_wan": "",
          "bind_addr": "0.0.0.0",
          "bootstrap": false,
          %{ if consul_agent_mode == "server" }
          "bootstrap_expect": ${consul_server_count},
          %{ endif }
          "client_addr": "0.0.0.0",
          "data_dir": "/var/consul",
          "datacenter": "${consul_cluster_datacenter}",
          "disable_update_check": false,
          "domain": "${consul_cluster_domain}",
          "enable_local_script_checks": true,
          "enable_script_checks": false,
          "log_file": "/var/log/consul/consul.log",
          "log_level": "INFO",
          "log_rotate_bytes": 0,
          "log_rotate_duration": "24h",
          "log_rotate_max_files": 0,
          "node_name": "",
          "performance": {
              "leave_drain_time": "5s",
              "raft_multiplier": 1,
              "rpc_hold_timeout": "7s"
          },
          "ports": {
              "dns": 8600,
              "grpc": -1,
              "http": 8500,
              "https": -1,
              "serf_lan": 8301,
              "serf_wan": 8302,
              "server": 8300
          },
          "raft_protocol": 3,
          "retry_interval": "30s",
          "retry_interval_wan": "30s",
          "retry_join": ["provider=os tag_key=consul_cluster_name tag_value=${consul_cluster_name} domain_name=${os_auth_domain_name} user_name=${os_auth_username} password=${os_auth_password} auth_url=${os_auth_url} project_id=${os_project_id}"],
          "retry_max": 0,
          "retry_max_wan": 0,
          "server": %{ if consul_agent_mode == "server" }true%{ else }false%{ endif },
          "translate_wan_addrs": false,
          "ui": %{ if consul_agent_mode == "server" }true%{ else }false%{ endif },
          "disable_host_node_id": true
        }

    owner: consul:bin
    path: /etc/consul/config.json
    permissions: '644'
-   content: |
        {{ range services }}{{ if .Tags | contains "web" }}
        ## Service: {{.Name}}
        upstream {{.Name}} {
        least_conn;
        {{range service .Name "passing" }}server {{.Address}}:{{.Port}} max_fails=3 fail_timeout=60 weight=1;
        {{else}}server 127.0.0.1:65535; # force a 502{{end}}
        }
        server {
            listen 80;
            server_name {{.Name}}.${project_root_domain};

            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Server $host;
            proxy_set_header X-Real-IP $remote_addr;

            location /favicon {
                empty_gif;
                access_log off;
                log_not_found off;
            }

            location / {
                proxy_pass http://{{.Name}};
            }
        }
        {{ end }}{{ end }}

    owner: root:root
    path: /opt/consul-template/templates/nginx-template.ctmpl
    permissions: '644'
-   content: |
        app_mode = production
        instance_name = $${HOSTNAME}
        [paths]
        data = data
        plugins = /var/lib/grafana/plugins
        provisioning = /var/lib/grafana/provisioning
        [server]
        protocol = http
        http_addr =
        http_port = 3000
        root_url = http://grafana.${project_root_domain}
        [database]
        type = sqlite3
        path = /var/lib/grafana/grafana.db
        [session]
        provider = file
        [security]
        admin_user = admin
        admin_password = admin
        secret_key = SW2YcwTIb9zpOOhoPsMm
        [auth]
        disable_login_form = false
        disable_signout_menu = false
        signout_redirect_url = 
        oauth_auto_login = false
        #################################### Generic OAuth #######################
        [auth.generic_oauth]
        name = Dinivas
        enabled = true
        allow_sign_up = true
        client_id = ${keycloak_grafana_client_id}
        client_secret = ${keycloak_grafana_client_secret}
        scopes = user:email
        email_attribute_name = email:primary
        auth_url = ${project_keycloak_scheme}://${project_keycloak_host}/auth/realms/${project_keycloak_realm}/protocol/openid-connect/auth
        token_url = ${project_keycloak_scheme}://${project_keycloak_host}/auth/realms/${project_keycloak_realm}/protocol/openid-connect/token
        api_url = ${project_keycloak_scheme}://${project_keycloak_host}/auth/realms/${project_keycloak_realm}/protocol/openid-connect/userinfo
        team_ids =
        allowed_organizations =
        tls_skip_verify_insecure = false
        tls_client_cert =
        tls_client_key =
        tls_client_ca =
        [explore]
        enabled = true
        [metrics]
        enabled           = true
        interval_seconds  = 10


    path: /etc/grafana/grafana.ini
    owner: grafana:grafana
    permissions: '644'
-   content: |
        {"service":
            {"name": "grafana-metrics",
            "tags": ["monitor"],
            "port": 3000
            }
        }

    owner: consul:bin
    path: /etc/consul/consul.d/grafana-metrics-service.json
    permissions: '644'
-   content: |
        #!/bin/sh

        sed -i '1inameserver 127.0.0.1' /etc/resolv.conf

        #Remove Consul existing datas
        chmod -R 755 /var/consul
        rm -R /var/consul/*

        instance_ip4=$(ip addr show dev eth0 | grep inet | awk '{print $2}' | head -1 | cut -d/ -f1)
        instance_hostname=$(hostname -s)

        echo " ===> Configuring Consul"
        # Update value in consul config.json
        tmp=$(mktemp)
        jq ".advertise_addr |= \"$instance_ip4\"" /etc/consul/config.json > "$tmp" && mv -f "$tmp" /etc/consul/config.json
        jq ".advertise_addr_wan |= \"$instance_ip4\"" /etc/consul/config.json > "$tmp" && mv -f "$tmp" /etc/consul/config.json
        jq ".node_name |= \"$instance_hostname\"" /etc/consul/config.json > "$tmp" && mv -f "$tmp" /etc/consul/config.json

        echo " ===> Restart Consul"
        systemctl restart consul

        echo " ===> Restart Consul-template"
        systemctl restart consul-template

        echo " ===> Restart Grafana"
        systemctl restart grafana-server

        # Allow to connect to upstream
        setsebool -P httpd_can_network_connect 1

    path: /etc/configure-consul.sh
    permissions: '744'