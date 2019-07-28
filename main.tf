
# ************************** Networks setup ************************************

## Management network
module "mgmt_network" {
  #source              = "../terraform-os-network/"
  source              = "git@github.com:dinivas/terraform-openstack-network.git"
  network_name        = "${var.project_name}-mgmt"
  network_tags        = ["${var.project_name}", "management", "dinivas"]
  network_description = "${var.project_description}"

  subnets = [
    {
      subnet_name       = "${var.project_name}-mgmt-subnet"
      subnet_cidr       = "${var.mgmt_subnet_cidr}"
      subnet_ip_version = 4
      subnet_tags       = "${var.project_name}, management, dinivas"
    }
  ]
}

# ************************** Router setup *****************************************

## Private router

data "openstack_networking_network_v2" "public_network" {
  name = "public"
}

resource "openstack_networking_router_v2" "project_router" {
  name                = "${var.project_name}-router"
  admin_state_up      = true
  external_network_id = "${data.openstack_networking_network_v2.public_network.id}"
}
resource "openstack_networking_router_interface_v2" "router_interface_mgmt" {
  router_id = "${openstack_networking_router_v2.project_router.id}"
  subnet_id = "${module.mgmt_network.subnet_ids[0]}"
}

# ************************** Security Groups setup*********************************

# Common
module "common_security_group" {
  #source      = "../terraform-os-security-group"
  source      = "git@github.com:dinivas/terraform-openstack-security-group.git"
  name        = "${var.project_name}-common"
  description = "${format("%s common security group", var.project_name)}"
  rules       = "${var.common_security_group_rules}"
}

# ************************** Keypair setup*******************************************

module "bastion_generated_keypair" {
  #source           = "../terraform-os-keypair"
  source           = "git@github.com:dinivas/terraform-openstack-keypair.git"
  name             = "${var.project_name}-bastion-generated-keypair"
  generate_ssh_key = true
}

resource "local_file" "bastion_private_key" {
  content  = "${module.bastion_generated_keypair.private_key}"
  filename = "${var.bastion_private_key_output_directory != "" ? var.bastion_private_key_output_directory : path.cwd}/${var.project_name}-bastion.key"
}

module "project_generated_keypair" {
  #source           = "../terraform-os-keypair"
  source           = "git@github.com:dinivas/terraform-openstack-keypair.git"
  name             = "${var.project_name}"
  generate_ssh_key = true
}

# ************************** Floating Ips *******************************************

## Bastion
data "openstack_networking_floatingip_v2" "bastion_floatingip" {
  count = "${var.bastion_existing_floating_ip_to_use != "" ? 1 : 0}"

  address = "${var.bastion_existing_floating_ip_to_use}"
}

resource "openstack_networking_floatingip_v2" "bastion_floatingip" {
  count = "${var.floating_ip_pool != "" ? 1 : 0}"

  pool = "${var.floating_ip_pool}"
}

locals {
  bastion_floating_ip = "${var.bastion_existing_floating_ip_to_use != "" ? data.openstack_networking_floatingip_v2.bastion_floatingip.0.address : openstack_networking_floatingip_v2.bastion_floatingip.0.address}"
}

resource "openstack_compute_floatingip_associate_v2" "bastion_floatingip_associate" {
  floating_ip           = "${local.bastion_floating_ip}"
  instance_id           = "${module.bastion_compute.ids[0]}"
  fixed_ip              = "${module.bastion_compute.network_fixed_ip_v4[0]}"
  wait_until_associated = true
}

# ************************** Compute (bastion) setup*********************************

module "bastion_compute" {
  #source = "../terraform-os-compute"
  source               = "git@github.com:dinivas/terraform-openstack-instance.git"
  instance_name                 = "bastion-${var.project_name}"
  image_name                    = "${var.bastion_image_name}"
  flavor_name                   = "${var.bastion_compute_flavor_name}"
  keypair                       = "${module.bastion_generated_keypair.name}"
  network_ids                   = ["${module.mgmt_network.network_id}"]
  subnet_ids                    = ["${module.mgmt_network.subnet_ids}"]
  instance_security_group_name  = "${var.project_name}-bastion"
  instance_security_group_rules = "${var.bastion_security_group_rules}"
  security_groups_to_associate  = ["${module.common_security_group.name}"]
  metadata                      = "${var.metadata}"
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

# ***********************
