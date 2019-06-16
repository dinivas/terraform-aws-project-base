module "shepherdcloud_base" {
  source = "../../"

  project_name                = "lcm"
  project_description         = "Linkycom is the best"
  public_router_name          = "router1"
  bastion_image_name          = "Centos 7"
  bastion_compute_flavor_name = "m1.small"
  bastion_ssh_user            = "centos"
}
