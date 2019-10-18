# ******************************* Proxy setup ***********************************

data "template_file" "proxy_user_data" {
  count = "${var.enable_proxy}"

  template = "${data.http.generic_user_data_template.body}"

  vars = {
    consul_agent_mode         = "client"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    os_auth_domain_name       = "${var.os_auth_domain_name}"
    os_auth_username          = "${var.os_auth_username}"
    os_auth_password          = "${var.os_auth_password}"
    os_auth_url               = "${var.os_auth_url}"
    os_project_id             = "${var.os_project_id}"

    pre_configure_script     = ""
    custom_write_files_block = "${data.template_file.proxy_custom_user_data_write_files.0.rendered}"
    post_configure_script    = "${data.template_file.proxy_custom_user_data_post_script.0.rendered}"
  }

}

data "template_file" "proxy_custom_user_data_post_script" {
  count = "${var.enable_proxy}"

  template = "${file("${path.module}/templates/proxy-user-data-post-script.tpl")}"
}

data "template_file" "proxy_custom_user_data_write_files" {
  count = "${var.enable_proxy}"

  template = "${file("${path.module}/templates/proxy-user-data-write-files.tpl")}"

  vars = {
    project_root_domain            = "${var.project_root_domain}"
    project_keycloak_scheme        = "${var.project_keycloak_scheme}"
    project_keycloak_host          = "${var.project_keycloak_host}"
    project_keycloak_realm         = "${keycloak_realm.project_realm.id}"
    keycloak_grafana_client_id     = "${keycloak_openid_client.grafana_client.client_id}"
    keycloak_grafana_client_secret = "${keycloak_openid_client.grafana_client.client_secret}"
  }
}

module "proxy_compute" {
  source = "../terraform-openstack-instance"

  #source = "github.com/dinivas/terraform-openstack-instance"

  enabled = "${var.enable_proxy}"

  instance_name                 = "${var.project_name}-proxy"
  image_name                    = "${var.proxy_image_name}"
  flavor_name                   = "${var.proxy_compute_flavor_name}"
  keypair                       = "${module.project_generated_keypair.name}"
  network_ids                   = ["${module.mgmt_network.network_id}"]
  subnet_ids                    = ["${module.mgmt_network.subnet_ids}"]
  instance_security_group_name  = "${var.project_name}-proxy-sg"
  instance_security_group_rules = "${var.proxy_security_group_rules}"
  security_groups_to_associate  = ["${module.common_security_group.name}"]
  user_data                     = "${data.template_file.proxy_user_data.0.rendered}"
  metadata                      = "${merge(var.metadata, map("consul_cluster_name", format("%s-%s", var.project_name, "consul")), map("project", var.project_name))}"
  availability_zone             = "${var.project_availability_zone}"

  execute_on_destroy_instance_script = "consul leave"

  ssh_via_bastion_config = {
    host_private_key    = "${module.project_generated_keypair.private_key}"
    bastion_host        = "${local.bastion_floating_ip}"
    bastion_private_key = "${module.bastion_generated_keypair.private_key}"
  }
}

data "openstack_networking_floatingip_v2" "proxy_floatingip" {
  count = "${var.proxy_prefered_floating_ip != "" ? var.enable_proxy * 1 : 0}"

  address = "${var.proxy_prefered_floating_ip}"
}

resource "openstack_networking_floatingip_v2" "proxy_floatingip" {
  count = "${var.floating_ip_pool != "" && var.proxy_prefered_floating_ip == "" ? var.enable_proxy * 1 : 0}"

  pool = "${var.floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "proxy_floatingip_associate" {
  count = "${var.enable_proxy}"

  floating_ip           = "${var.proxy_prefered_floating_ip != "" ? data.openstack_networking_floatingip_v2.proxy_floatingip.0.address : openstack_networking_floatingip_v2.proxy_floatingip.0.address}"
  instance_id           = "${module.proxy_compute.ids[0]}"
  fixed_ip              = "${module.proxy_compute.network_fixed_ip_v4[0]}"
  wait_until_associated = true
}
