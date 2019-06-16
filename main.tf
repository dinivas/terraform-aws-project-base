
# ************************** Networks setup ************************************

## Management network
module "mgmt_network" {
  source              = "../terraform-os-network/"
  network_name        = "${var.project_name}-mgmt-net"
  network_tags        = ["${var.project_name}", "management", "shepherdcloud"]
  network_description = "${var.project_description}"

  subnets = [
    {
      subnet_name       = "${var.project_name}-mgmt-subnet"
      subnet_cidr       = "10.10.11.0/24"
      subnet_ip_version = 4
      subnet_tags       = "${var.project_name}, management, shepherdcloud"
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

module "bastion_security_group" {
  source      = "../terraform-os-security-group"
  name        = "${var.project_name}-bastion"
  description = "Bastion security group"
  rules       = "${var.bastion_security_group_rules}"
}


# ************************** Keypair setup*******************************************

module "bastion_generated_keypair" {
  source           = "../terraform-os-keypair"
  name             = "${var.project_name}-bastion-generated-keypair"
  generate_ssh_key = true
}

resource "local_file" "bastion_private_key" {
  content  = "${module.bastion_generated_keypair.private_key}"
  filename = "${var.bastion_private_key_output_directory != "" ? var.bastion_private_key_output_directory : path.module}/${var.project_name}-bastion.key"
}

module "project_generated_keypair" {
  source           = "../terraform-os-keypair"
  name             = "${var.project_name}-keypair"
  generate_ssh_key = true
}

# ************************** Floating Ips *******************************************

## Bastion
data "openstack_networking_floatingip_v2" "bastion_floatingip" {
  count = "${var.bastion_existing_floating_ip_to_use != "" ? 1 : 0}"

  address = "${var.bastion_existing_floating_ip_to_use}"
}

resource "openstack_networking_floatingip_v2" "this" {
  count = "${var.floating_ip_pool != "" ? 1 : 0}"

  pool = "${var.floating_ip_pool}"
}

locals {
  bastion_floating_ip = "${var.bastion_existing_floating_ip_to_use != "" ? data.openstack_networking_floatingip_v2.bastion_floatingip.0.address : openstack_networking_floatingip_v2.this.0.address}"
}

resource "openstack_compute_floatingip_associate_v2" "bastion_floatingip_associate" {
  floating_ip           = "${local.bastion_floating_ip}"
  instance_id           = "${module.bastion_compute.ids[0]}"
  fixed_ip              = "${module.bastion_compute.network_fixed_ip_v4[0]}"
  wait_until_associated = true
}

# ************************** Compute (bastion) setup*********************************

module "bastion_compute" {
  source               = "../terraform-os-compute"
  instance_name        = "${var.project_name}-bastion"
  image_name           = "${var.bastion_image_name}"
  flavor_name          = "${var.bastion_compute_flavor_name}"
  keypair              = "${module.bastion_generated_keypair.name}"
  network_ids          = ["${module.mgmt_network.network_id}"]
  subnet_ids           = ["${module.mgmt_network.subnet_ids}"]
  security_group_name  = "${var.project_name}-sg"
  security_group_rules = "${var.bastion_security_group_rules}"
}


resource "null_resource" "provision_project_private_key_to_bastion" {
  triggers = {
    bastion_instance_id = "${module.bastion_compute.ids[0]}"
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
