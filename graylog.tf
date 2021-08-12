# ******************************* Graylog setup ***********************************

data "template_file" "graylog_user_data" {
  count = var.enable_logging_graylog

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
    custom_write_files_block = data.template_file.graylog_custom_user_data_write_files.0.rendered
    post_configure_script    = data.template_file.graylog_custom_user_data_post_script.0.rendered
  }

}

data "template_file" "graylog_custom_user_data_post_script" {
  count = var.enable_logging_graylog

  template = file("${path.module}/templates/graylog-user-data-post-script.tpl")

  vars = {
    project_root_domain = var.project_root_domain
  }
}

data "template_file" "graylog_custom_user_data_write_files" {
  count = var.enable_logging_graylog

  template = file("${path.module}/templates/graylog-user-data-write-files.tpl")

  vars = {
    project_root_domain     = var.project_root_domain
    project_keycloak_scheme = var.project_keycloak_scheme
    project_keycloak_host   = var.project_keycloak_host
    project_keycloak_realm  = keycloak_realm.project_realm.id
  }
}

# resource "openstack_networking_secgroup_v2" "graylog" {
#   name        = "${var.project_name}-graylog-sg"
#   description = format("%s project Graylog security group", var.project_name)
# }

# resource "openstack_networking_secgroup_rule_v2" "graylog" {
#   count = length(var.graylog_security_group_rules)

#   port_range_min    = lookup(var.graylog_security_group_rules[count.index], "port_range_min", 0)
#   port_range_max    = lookup(var.graylog_security_group_rules[count.index], "port_range_max", 0)
#   protocol          = lookup(var.graylog_security_group_rules[count.index], "protocol")
#   direction         = lookup(var.graylog_security_group_rules[count.index], "direction")
#   ethertype         = lookup(var.graylog_security_group_rules[count.index], "ethertype")
#   remote_ip_prefix  = lookup(var.graylog_security_group_rules[count.index], "remote_ip_prefix", "")
#   security_group_id = openstack_networking_secgroup_v2.graylog.id
# }

resource "aws_instance" "graylog" {
  count = var.enable_logging_graylog

  ami               = var.graylog_compute_image_name
  instance_type     = var.graylog_compute_flavour_name
  key_name          = aws_key_pair.project_ssh_key.key_name
  availability_zone = var.project_availability_zone
  user_data         = data.template_file.graylog_user_data.0.rendered

  vpc_security_group_ids = [aws_security_group.private_subnet.id]

  subnet_id = aws_subnet.private.id
  tags = {
    Name = format("%s-%s", var.project_name, "graylog")
  }
}
