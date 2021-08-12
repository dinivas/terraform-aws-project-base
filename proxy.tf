# ******************************* Proxy setup ***********************************

data "template_file" "proxy_user_data" {
  count = var.enable_proxy

  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "aws"
    project_name              = var.project_name
    consul_agent_mode         = "client"
    consul_cluster_domain     = var.project_consul_domain
    consul_cluster_datacenter = var.project_consul_datacenter
    consul_cluster_name       = "${var.project_name}-consul"
    aws_region                = var.aws_region
    aws_access_key_id         = var.aws_access_key_id
    aws_secret_access_key     = var.aws_secret_access_key
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


resource "aws_instance" "proxy" {

  ami               = var.proxy_image_name
  instance_type     = var.proxy_compute_flavor_name
  key_name          = aws_key_pair.project_ssh_key.key_name
  availability_zone = var.project_availability_zone
  user_data         = data.template_file.proxy_user_data.0.rendered

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.common.id, aws_security_group.public_subnet.id, aws_security_group.web.id]

  depends_on = [aws_internet_gateway.this]
  tags = {
    Name = format("%s-proxy", var.project_name)
  }
}

data "aws_eip" "proxy_floatingip" {
  count = var.proxy_prefered_floating_ip != "" ? var.enable_proxy * 1 : 0

  public_ip = var.proxy_prefered_floating_ip
}

resource "aws_eip" "proxy_floatingip" {
  count = var.proxy_prefered_floating_ip == "" ? var.enable_proxy * 1 : 0
}

resource "aws_eip_association" "proxy_floatingip_associate" {
  count = var.enable_proxy

  allocation_id = var.proxy_prefered_floating_ip != "" ? data.aws_eip.proxy_floatingip.0.id : aws_eip.proxy_floatingip.0.id
  instance_id   = aws_instance.proxy.id
}
