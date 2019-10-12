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
