# Project default Consul definition

# Consul servers definitions
data "template_file" "consul_server_user_data" {
  template = "${data.http.generic_user_data_template.body}"

  vars = {
    consul_agent_mode         = "server"
    consul_server_count       = "${var.project_consul_server_count}"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    os_auth_domain_name       = "${var.os_auth_domain_name}"
    os_auth_username          = "${var.os_auth_username}"
    os_auth_password          = "${var.os_auth_password}"
    os_auth_url               = "${var.os_auth_url}"
    os_project_id             = "${var.os_project_id}"

    pre_configure_script     = ""
    custom_write_files_block = "${data.template_file.consul_server_user_data_write_files.rendered}"
    post_configure_script    = ""
  }
}

data "template_file" "consul_server_user_data_write_files" {
  template = "${file("${path.module}/templates/consul-server-user-data.tpl")}"

  vars = {
    consul_cluster_name = "${var.project_name}-consul"
  }
}

resource "openstack_networking_secgroup_v2" "consul_server" {
  name        = "${format("%s-%s", var.project_name, "consul-server")}"
  description = "${format("Shared Consul server security group on project %s", var.project_name)}"
}

resource "openstack_compute_instance_v2" "consul_server" {
  count = "${var.project_consul_server_count * var.project_consul_enable}"

  depends_on = ["openstack_compute_instance_v2.bastion"]

  name                = "${format("%s-%s-%s", var.project_name, "consul-server", count.index)}"
  image_name          = "${var.project_consul_server_image_name}"
  flavor_name           = "${var.project_consul_server_flavor_name}"
  key_pair            = "${var.project_name}"
  security_groups     = ["${openstack_networking_secgroup_v2.consul_server.name}", "${format("%s-common", var.project_name)}"]
  stop_before_destroy = true

  dynamic "network" {
    for_each = [module.mgmt_network.network_id]

    content {
      uuid = network.value
    }
  }

  metadata = {
    consul_cluster_name = "${var.project_name}-consul"
    project             = "${var.project_name}"
  }
  user_data = "${data.template_file.consul_server_user_data.rendered}"

  availability_zone = "${var.project_availability_zone}"
}

// Conditional floating ip on the first Consul server
resource "openstack_networking_floatingip_v2" "consul_cluster_floatingip" {
  count = "${var.project_consul_floating_ip_pool != "" ? var.project_consul_enable * 1 : 0}"

  pool = "${var.project_consul_floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "consul_cluster_floatingip_associate" {
  count = "${var.project_consul_floating_ip_pool != "" ? var.project_consul_enable * 1 : 0}"

  floating_ip           = "${lookup(openstack_networking_floatingip_v2.consul_cluster_floatingip[count.index], "address")}"
  instance_id           = "${lookup(openstack_compute_instance_v2.consul_server[count.index], "id")}"
  fixed_ip              = "${lookup(openstack_compute_instance_v2.consul_server[count.index].network.0, "fixed_ip_v4")}"
  wait_until_associated = true
}

# Consul client definitions

data "template_file" "consul_client_user_data" {
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
    custom_write_files_block = ""
    post_configure_script    = ""
  }
}

resource "openstack_networking_secgroup_v2" "consul_client" {
  name        = "${format("%s-%s", var.project_name, "consul-client")}"
  description = "${format("Shared Consul client security group on project %s", var.project_name)}"
}

resource "openstack_compute_instance_v2" "consul_client" {
  count = "${var.project_consul_client_count * var.project_consul_enable}"

  depends_on = ["openstack_compute_instance_v2.bastion"]

  name                = "${format("%s-%s-%s", var.project_name, "consul-client", count.index)}"
  image_name          = "${var.project_consul_client_image_name}"
  flavor_name           = "${var.project_consul_client_flavor_name}"
  key_pair            = "${var.project_name}"
  security_groups     = ["${openstack_networking_secgroup_v2.consul_client.name}", "${format("%s-common", var.project_name)}"]
  stop_before_destroy = true

  dynamic "network" {
    for_each = [module.mgmt_network.network_id]

    content {
      uuid = network.value
    }
  }

  metadata = {
    consul_cluster_name = "${var.project_name}-consul"
    project             = "${var.project_name}"
  }
  user_data = "${data.template_file.consul_client_user_data.rendered}"

  availability_zone = "${var.project_availability_zone}"

  connection {
    type        = "ssh"
    user        = "centos"
    port        = 22
    host        = "${self.access_ip_v4}"
    private_key = "${module.project_generated_keypair.private_key}"
    agent       = false

    bastion_host        = "${local.bastion_floating_ip}"
    bastion_port        = 22
    bastion_user        = "centos"
    bastion_private_key = "${module.bastion_generated_keypair.private_key}"
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "consul leave",
    ]
    on_failure = "continue"
  }
}
