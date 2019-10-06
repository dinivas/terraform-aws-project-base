variable "os_auth_domain_name" {
  type    = "string"
  default = "default"
}
variable "os_auth_username" {}

variable "os_auth_password" {}
variable "os_auth_url" {}
variable "os_project_id" {}
variable "project_keycloak_host" {}

module "dinivas_project_base" {
  source = "../../"

  project_name                      = "dnv"
  project_description               = ""
  project_root_domain               = "dinivas.remote"
  project_availability_zone         = "nova:node03"
  public_router_name                = "router1"
  mgmt_subnet_cidr                  = "10.10.13.0/24"
  mgmt_subnet_dhcp_allocation_start = "10.10.13.2"
  mgmt_subnet_dhcp_allocation_end   = "10.10.13.254"
  bastion_image_name                = "Dinivas Base"
  bastion_compute_flavor_name       = "dinivas.medium"
  bastion_ssh_user                  = "centos"
  prometheus_image_name             = "ShepherdCloud Prometheus"
  prometheus_compute_flavor_name    = "dinivas.medium"
  enable_proxy                      = "1"
  enable_prometheus                 = "0"
  proxy_image_name                  = "Dinivas Proxy"
  proxy_compute_flavor_name         = "dinivas.large"

  project_consul_enable           = "1"
  project_consul_domain           = "dinivas"
  project_consul_datacenter       = "gra"
  project_consul_server_count     = 1
  project_consul_client_count     = 1
  project_consul_floating_ip_pool = ""

  project_keycloak_host          = "${var.project_keycloak_host}"

  os_auth_domain_name = "${var.os_auth_domain_name}"
  os_auth_username    = "${var.os_auth_username}"
  os_auth_password    = "${var.os_auth_password}"
  os_auth_url         = "${var.os_auth_url}"
  os_project_id       = "${var.os_project_id}"
}
