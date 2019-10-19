# ************************** Compute (bastion) setup*********************************

data "template_file" "bastion_user_data" {
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
    post_configure_script    = ""
    custom_write_files_block = ""
  }
}

resource "openstack_networking_secgroup_v2" "bastion" {
  name        = "${var.project_name}-bastion"
  description = "${format("%s project Bastion security group", var.project_name)}"
}

resource "openstack_networking_secgroup_rule_v2" "bastion" {
  count = "${length(var.bastion_security_group_rules)}"

  port_range_min    = "${lookup(var.bastion_security_group_rules[count.index], "port_range_min", 0)}"
  port_range_max    = "${lookup(var.bastion_security_group_rules[count.index], "port_range_max", 0)}"
  protocol          = "${lookup(var.bastion_security_group_rules[count.index], "protocol")}"
  direction         = "${lookup(var.bastion_security_group_rules[count.index], "direction")}"
  ethertype         = "${lookup(var.bastion_security_group_rules[count.index], "ethertype")}"
  remote_ip_prefix  = "${lookup(var.bastion_security_group_rules[count.index], "remote_ip_prefix", "")}"
  security_group_id = "${openstack_networking_secgroup_v2.bastion.id}"
}

resource "openstack_compute_instance_v2" "bastion" {

  depends_on = ["module.mgmt_network.subnet_ids"]

  name            = "${var.project_name}-bastion"
  image_name      = "${var.bastion_image_name}"
  flavor_name     = "${var.bastion_compute_flavor_name}"
  key_pair        = "${module.bastion_generated_keypair.name}"
  user_data       = "${data.template_file.bastion_user_data.rendered}"
  security_groups = ["${module.common_security_group.name}", "${openstack_networking_secgroup_v2.bastion.name}"]
  metadata        = "${merge(var.metadata, map("consul_cluster_name", format("%s-%s", var.project_name, "consul")), map("project", var.project_name))}"
  network {
    name = "${var.project_name}-mgmt"
  }
  availability_zone = "${var.project_availability_zone}"
}


resource "null_resource" "provision_project_private_key_to_bastion" {
  triggers = {
    bastion_instance_id    = "${openstack_compute_instance_v2.bastion.id}"
    bastion_floating_ip_id = "${openstack_compute_floatingip_associate_v2.bastion_floatingip_associate.id}"
  }

  provisioner "file" {
    content     = "${module.project_generated_keypair.private_key}"
    destination = "~/.ssh/${var.project_name}.key"

    connection {
      type        = "ssh"
      host        = "${local.bastion_floating_ip}"
      user        = "${var.bastion_ssh_user}"
      private_key = "${module.bastion_generated_keypair.private_key}"
    }
  }
}

resource "openstack_compute_floatingip_associate_v2" "bastion_floatingip_associate" {
  floating_ip           = "${local.bastion_floating_ip}"
  instance_id           = "${openstack_compute_instance_v2.bastion.id}"
  fixed_ip              = "${openstack_compute_instance_v2.bastion.network.0.fixed_ip_v4}"
  wait_until_associated = true
}

# ***********************
