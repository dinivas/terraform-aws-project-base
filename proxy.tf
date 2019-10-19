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

resource "openstack_networking_secgroup_v2" "proxy" {
  name        = "${var.project_name}-proxy-sg"
  description = "${format("%s project Proxy security group", var.project_name)}"
}

resource "openstack_networking_secgroup_rule_v2" "proxy" {
  count = "${length(var.proxy_security_group_rules)}"

  port_range_min    = "${lookup(var.proxy_security_group_rules[count.index], "port_range_min", 0)}"
  port_range_max    = "${lookup(var.proxy_security_group_rules[count.index], "port_range_max", 0)}"
  protocol          = "${lookup(var.proxy_security_group_rules[count.index], "protocol")}"
  direction         = "${lookup(var.proxy_security_group_rules[count.index], "direction")}"
  ethertype         = "${lookup(var.proxy_security_group_rules[count.index], "ethertype")}"
  remote_ip_prefix  = "${lookup(var.proxy_security_group_rules[count.index], "remote_ip_prefix", "")}"
  security_group_id = "${openstack_networking_secgroup_v2.proxy.id}"
}

resource "openstack_compute_instance_v2" "proxy" {

  depends_on = ["module.mgmt_network.subnet_ids"]

  name            = "${var.project_name}-proxy"
  image_name      = "${var.proxy_image_name}"
  flavor_name     = "${var.proxy_compute_flavor_name}"
  key_pair        = "${module.project_generated_keypair.name}"
  user_data       = "${data.template_file.proxy_user_data.0.rendered}"
  security_groups = ["${module.common_security_group.name}", "${openstack_networking_secgroup_v2.proxy.name}"]
  metadata        = "${merge(var.metadata, map("consul_cluster_name", format("%s-%s", var.project_name, "consul")), map("project", var.project_name))}"
  network {
    name = "${var.project_name}-mgmt"
  }
  availability_zone = "${var.project_availability_zone}"
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
  instance_id           = "${openstack_compute_instance_v2.proxy.id}"
  fixed_ip              = "${openstack_compute_instance_v2.proxy.network.0.fixed_ip_v4}"
  wait_until_associated = true
}
