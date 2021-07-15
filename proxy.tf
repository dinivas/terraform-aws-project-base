# ******************************* Proxy setup ***********************************

data "template_file" "proxy_user_data" {
  count = var.enable_proxy

  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digitalocean"
    project_name              = var.project_name
    consul_agent_mode         = "client"
    consul_cluster_domain     = var.project_consul_domain
    consul_cluster_datacenter = var.project_consul_datacenter
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.project_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.enable_logging_graylog

    pre_configure_script     = ""
    custom_write_files_block = data.template_file.proxy_custom_user_data_write_files.0.rendered
    post_configure_script    = data.template_file.proxy_custom_user_data_post_script.0.rendered
  }

}

data "template_file" "proxy_custom_user_data_post_script" {
  count = var.enable_proxy

  template = file("${path.module}/templates/proxy-user-data-post-script.tpl")
}

data "template_file" "proxy_custom_user_data_write_files" {
  count = var.enable_proxy

  template = file("${path.module}/templates/proxy-user-data-write-files.tpl")

  vars = {
    project_root_domain            = "${var.project_root_domain}"
    project_keycloak_scheme        = "${var.project_keycloak_scheme}"
    project_keycloak_host          = "${var.project_keycloak_host}"
    project_keycloak_realm         = "${keycloak_realm.project_realm.id}"
    keycloak_grafana_client_id     = "${keycloak_openid_client.grafana_client.client_id}"
    keycloak_grafana_client_secret = "${keycloak_openid_client.grafana_client.client_secret}"
  }
}

# resource "openstack_networking_secgroup_v2" "proxy" {
#   name        = "${var.project_name}-proxy-sg"
#   description = format("%s project Proxy security group", var.project_name)
# }

# resource "openstack_networking_secgroup_rule_v2" "proxy" {
#   count = length(var.proxy_security_group_rules)

#   port_range_min    = lookup(var.proxy_security_group_rules[count.index], "port_range_min", 0)
#   port_range_max    = lookup(var.proxy_security_group_rules[count.index], "port_range_max", 0)
#   protocol          = lookup(var.proxy_security_group_rules[count.index], "protocol")
#   direction         = lookup(var.proxy_security_group_rules[count.index], "direction")
#   ethertype         = lookup(var.proxy_security_group_rules[count.index], "ethertype")
#   remote_ip_prefix  = lookup(var.proxy_security_group_rules[count.index], "remote_ip_prefix", "")
#   security_group_id = openstack_networking_secgroup_v2.proxy.id
# }

resource "digitalocean_droplet" "proxy" {

  name               = "${var.project_name}-proxy"
  image              = var.proxy_image_name
  size               = var.proxy_compute_flavor_name
  ssh_keys           = [module.project_ssh_key.id]
  region             = var.project_availability_zone
  vpc_uuid           = module.mgmt_network.vpc_id
  user_data          = data.template_file.proxy_user_data.0.rendered
  tags               = concat([digitalocean_tag.project.name], split(",", format("consul_cluster_name_%s-%s,project_%s", var.project_name, "consul", var.project_name)))
  private_networking = true
}

data "digitalocean_floating_ip" "proxy_floatingip" {
  count = var.proxy_prefered_floating_ip != "" ? var.enable_proxy * 1 : 0

  ip_address = var.proxy_prefered_floating_ip
}

resource "digitalocean_floating_ip" "proxy_floatingip" {
  count = var.proxy_prefered_floating_ip == "" ? var.enable_proxy * 1 : 0

  region = var.project_availability_zone
}

resource "digitalocean_floating_ip_assignment" "proxy_floatingip_associate" {
  count = var.enable_proxy

  ip_address = var.proxy_prefered_floating_ip != "" ? var.proxy_prefered_floating_ip : digitalocean_floating_ip.proxy_floatingip.0.ip_address
  droplet_id = digitalocean_droplet.proxy.id
}
