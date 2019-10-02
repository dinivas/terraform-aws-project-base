# Project default Consul definition

module "project_consul_cluster" {
  source = "github.com/dinivas/terraform-openstack-consul"

  enable_consul_cluster                       = "${var.project_consul_enable}"
  consul_cluster_name                         = "${var.project_name}-consul"
  consul_cluster_domain                       = "${var.project_consul_domain}"
  consul_cluster_datacenter                   = "${var.project_consul_datacenter}"
  consul_cluster_availability_zone            = "${var.project_availability_zone}"
  consul_cluster_network_id                   = "${module.mgmt_network.network_id}"
  consul_cluster_subnet_id                    = ["${module.mgmt_network.subnet_ids}"]
  consul_cluster_floating_ip_pool             = "${var.floating_ip_pool}"
  consul_server_instance_count                = "${var.project_consul_server_count}"
  consul_server_image_name                    = "${var.project_consul_server_image_name}"
  consul_server_flavor_name                   = "${var.project_consul_server_flavor_name}"
  consul_server_keypair_name                  = "${var.project_name}"
  consul_client_instance_count                = "${var.project_consul_client_count}"
  consul_client_image_name                    = "${var.project_consul_client_image_name}"
  consul_client_flavor_name                   = "${var.project_consul_client_flavor_name}"
  consul_client_keypair_name                  = "${var.project_name}"
  consul_cluster_security_groups_to_associate = ["${var.project_name}-common"]
  consul_cluster_metadata = {
    consul_cluster_name = "${var.project_name}-consul"
  }
  os_auth_domain_name = "${var.os_auth_domain_name}"
  os_auth_username    = "${var.os_auth_username}"
  os_auth_password    = "${var.os_auth_password}"
  os_auth_url         = "${var.os_auth_url}"
  os_project_id       = "${var.os_project_id}"
}
