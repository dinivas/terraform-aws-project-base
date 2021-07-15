#!/bin/sh


echo " ===> Running Graylog Post script from user data (Cloud-Init)"
sed -i 's/http_publish_uri = http:\/\/0.0.0.0:9000\//http_publish_uri = http:\/\/graylog.${project_root_domain}\//g' /etc/graylog/server/server.conf
sed -i 's/http_external_uri = http:\/\/0.0.0.0:9000\//http_external_uri = http:\/\/graylog.${project_root_domain}\//g' /etc/graylog/server/server.conf
echo " ===> Restart Graylog"
systemctl restart graylog-server