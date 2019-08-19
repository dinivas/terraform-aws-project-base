module "dinivas_project_base" {
  source = "../../"

  project_name                   = "dinivas"
  project_description            = "This project is for demo purpose"
  public_router_name             = "router1"
  bastion_image_name             = "Centos 7"
  bastion_compute_flavor_name    = "m1.small"
  bastion_ssh_user               = "centos"
  prometheus_image_name          = "ShepherdCloud Prometheus"
  prometheus_compute_flavor_name = "m1.small"
  enable_prometheus              = "1"
  proxy_image_name               = "Centos 7"
  proxy_compute_flavor_name      = "m1.small"
}
