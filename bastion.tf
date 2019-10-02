# ************************** Compute (bastion) setup*********************************

data "template_file" "bastion_user_data" {
  template = "${file("${path.module}/templates/bastion-user-data.tpl")}"

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
  }
}

module "bastion_compute" {
  #source = "../terraform-os-compute"
  source                        = "github.com/dinivas/terraform-openstack-instance"
  instance_name                 = "${var.project_name}-bastion"
  image_name                    = "${var.bastion_image_name}"
  flavor_name                   = "${var.bastion_compute_flavor_name}"
  keypair                       = "${module.bastion_generated_keypair.name}"
  network_ids                   = ["${module.mgmt_network.network_id}"]
  subnet_ids                    = ["${module.mgmt_network.subnet_ids}"]
  instance_security_group_name  = "${var.project_name}-bastion"
  instance_security_group_rules = "${var.bastion_security_group_rules}"
  security_groups_to_associate  = ["${module.common_security_group.name}"]
  user_data                     = "${data.template_file.bastion_user_data.rendered}"
  metadata          = "${merge(var.metadata, map("consul_cluster_name", format("%s-%s", var.project_name, "consul")))}"
  availability_zone = "${var.project_availability_zone}"
}


resource "null_resource" "provision_project_private_key_to_bastion" {
  triggers = {
    bastion_instance_id    = "${module.bastion_compute.ids[0]}"
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
  instance_id           = "${module.bastion_compute.ids[0]}"
  fixed_ip              = "${module.bastion_compute.network_fixed_ip_v4[0]}"
  wait_until_associated = true
}

# ***********************