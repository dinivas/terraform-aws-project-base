#!/bin/sh

echo " ===> Restart Consul-template"
systemctl restart consul-template

echo " ===> Restart Grafana"
systemctl restart grafana-server

# Allow to connect to upstream
setsebool -P httpd_can_network_connect 1