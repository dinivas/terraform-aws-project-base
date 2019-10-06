resource "keycloak_realm" "project_realm" {
  realm   = "${var.project_name}"
  enabled = true
}

resource "keycloak_openid_client" "grafana_client" {
  realm_id              = "${keycloak_realm.project_realm.id}"
  client_id             = "grafana"
  name                  = "grafana"
  enabled               = true
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris = [
    "*"
  ]
}

resource "keycloak_openid_client" "jenkins_client" {
  realm_id                     = "${keycloak_realm.project_realm.id}"
  client_id                    = "jenkins"
  name                         = "jenkins"
  enabled                      = true
  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  direct_access_grants_enabled = true
  valid_redirect_uris = [
    "*"
  ]
}
