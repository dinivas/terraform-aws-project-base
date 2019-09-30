module "dinivas_project_base" {
  source = "../../"

  project_name                   = "dinivas"
  project_description            = "This project is for demo purpose"
  public_router_name             = "router1"
  mgmt_subnet_cidr               = "10.10.11.1/24"
  bastion_image_name             = "Centos 7"
  bastion_compute_flavor_name    = "m1.small"
  bastion_ssh_user               = "centos"
  prometheus_image_name          = "ShepherdCloud Prometheus"
  prometheus_compute_flavor_name = "m1.small"
  enable_proxy                   = "0"
  enable_prometheus              = "0"
  proxy_image_name               = "Centos 7"
  proxy_compute_flavor_name      = "m1.small"

  project_consul_enable = "1"
  project_consul_domain = "dinivas"
  project_consul_datacenter = "gra"
  project_consul_server_count = 3
  project_consul_client_count = 1

}
