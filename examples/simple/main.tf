variable "project_keycloak_host" {}
variable "do_api_token" {}

module "dinivas_project_base" {
  source = "../../"

  project_name                      = "dnv"
  project_description               = ""
  project_root_domain               = "157.245.16.138.nip.io"
  project_availability_zone         = "fra1"
  public_router_name                = "router1"
  mgmt_subnet_cidr                  = "10.10.13.0/24"
  mgmt_subnet_dhcp_allocation_start = "10.10.13.2"
  mgmt_subnet_dhcp_allocation_end   = "10.10.13.254"
  bastion_image_name                = 87674237 # "Dinivas Base 2021-07-11"
  bastion_compute_flavor_name       = "s-1vcpu-1gb"
  bastion_ssh_user                  = "root"
  prometheus_image_name             = "ShepherdCloud Prometheus"
  prometheus_compute_flavor_name    = "s-1vcpu-1gb"
  enable_proxy                      = "1"
  enable_prometheus                 = "0"
  proxy_image_name                  = 87679113 # "Dinivas Proxy 2021-07-11"
  proxy_compute_flavor_name         = "s-1vcpu-2gb-intel"
  proxy_prefered_floating_ip        = "157.245.16.138"

  project_consul_enable             = "1"
  project_consul_domain             = "dinivas.io"
  project_consul_datacenter         = "fra1"
  project_consul_server_count       = 1
  project_consul_client_count       = 1
  project_consul_floating_ip_pool   = ""
  project_consul_server_image_name  = 87674237
  project_consul_server_flavor_name = "s-1vcpu-1gb"
  project_consul_client_image_name  = 87674237
  project_consul_client_flavor_name = "s-1vcpu-1gb"

  enable_logging_graylog       = "1"
  graylog_compute_image_name   = 87912224 # "Dinivas Graylog 4 AllInOne 2021-07-15"
  graylog_compute_flavour_name = "s-2vcpu-4gb"

  project_keycloak_host = var.project_keycloak_host
  do_api_token          = var.do_api_token
}
