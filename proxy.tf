# ******************************* Proxy setup ***********************************

module "proxy_compute" {
  #source = "../terraform-os-compute"
  source = "github.com/dinivas/terraform-openstack-instance"

  instance_name                 = "${var.project_name}-proxy"
  image_name                    = "${var.proxy_image_name}"
  flavor_name                   = "${var.proxy_compute_flavor_name}"
  keypair                       = "${module.project_generated_keypair.name}"
  network_ids                   = ["${module.mgmt_network.network_id}"]
  subnet_ids                    = ["${module.mgmt_network.subnet_ids}"]
  instance_security_group_name  = "${var.project_name}-proxy-sg"
  instance_security_group_rules = "${var.proxy_security_group_rules}"
  security_groups_to_associate  = ["${module.common_security_group.name}"]
  metadata                      = "${var.metadata}"
  enabled                       = "${var.enable_proxy}"
  availability_zone             = "${var.project_availability_zone}"
}

resource "openstack_networking_floatingip_v2" "proxy_floatingip" {
  count = "${var.floating_ip_pool != "" ? var.enable_proxy * 1 : 0}"

  pool = "${var.floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "proxy_floatingip_associate" {
  count = "${var.enable_proxy}"

  floating_ip           = "${openstack_networking_floatingip_v2.proxy_floatingip.0.address}"
  instance_id           = "${module.proxy_compute.ids[0]}"
  fixed_ip              = "${module.proxy_compute.network_fixed_ip_v4[0]}"
  wait_until_associated = true
}
