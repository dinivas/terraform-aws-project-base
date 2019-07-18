module "shepherdcloud_base" {
  source = "../../"

  project_name                = "shepherd"
  project_description         = "This project is for demo purpose"
  public_router_name          = "router1"
  bastion_image_name          = "Centos 7"
  bastion_compute_flavor_name = "m1.small"
  bastion_ssh_user            = "centos"
}
