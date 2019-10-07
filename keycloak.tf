resource "keycloak_realm" "project_realm" {
  realm   = "${var.project_name}"
  enabled = true
}

# Initial user
resource "keycloak_user" "user_with_initial_password" {
  realm_id = "${keycloak_realm.project_realm.id}"
  username = "${var.project_keycloak_initial_username}"
  enabled  = true

  email      = "${format("%s@%s", var.project_keycloak_initial_username, var.project_name)}"
  first_name = "${var.project_keycloak_initial_user_first_name}"
  last_name  = "${var.project_keycloak_initial_user_last_name}"

  initial_password {
    value     = "${var.project_keycloak_initial_user_password}"
    temporary = false
  }
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
