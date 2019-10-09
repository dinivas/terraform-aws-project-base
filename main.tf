
# ************************** Networks setup ************************************

## Management network
module "mgmt_network" {
  #source              = "../terraform-os-network/"
  source              = "github.com/dinivas/terraform-openstack-network"
  network_name        = "${var.project_name}-mgmt"
  network_tags        = ["${var.project_name}", "management", "dinivas"]
  network_description = "${var.project_description}"

  subnets = [
    {
      subnet_name           = "${var.project_name}-mgmt-subnet"
      subnet_cidr           = "${var.mgmt_subnet_cidr}"
      subnet_ip_version     = 4
      subnet_tags           = "${var.project_name}, management, dinivas"
      allocation_pool_start = "${var.mgmt_subnet_dhcp_allocation_start}"
      allocation_pool_end   = "${var.mgmt_subnet_dhcp_allocation_end}"
    }
  ]
}

# ************************** Router setup *****************************************

## Private router

## Use existing public router when public_router_name is defined
data "openstack_networking_router_v2" "public_router" {
  count = "${var.public_router_name != "" ? 1 : 0}"

  name = "${var.public_router_name}"
}

resource "openstack_networking_router_interface_v2" "public_router_interface_mgmt" {
  count = "${var.public_router_name != "" ? 1 : 0}"

  router_id = "${lookup(data.openstack_networking_router_v2.public_router[count.index], "id")}"
  subnet_id = "${module.mgmt_network.subnet_ids[0]}"
}

## Create project router when no public router is defined

data "openstack_networking_network_v2" "external_network" {
  count = "${var.public_router_name == "" ? 1 : 0}"

  name = "${var.external_network}"
}
resource "openstack_networking_router_v2" "project_router" {
  count = "${var.public_router_name == "" ? 1 : 0}"

  name                = "${var.project_name}-router"
  admin_state_up      = true
  external_network_id = "${data.openstack_networking_network_v2.external_network.0.id}"
}
resource "openstack_networking_router_interface_v2" "project_router_interface_mgmt" {
  count = "${var.public_router_name == "" ? 1 : 0}"

  router_id = "${lookup(openstack_networking_router_v2.project_router[count.index], "id")}"
  subnet_id = "${module.mgmt_network.subnet_ids[0]}"
}

# ************************** Security Groups setup*********************************

# Common
module "common_security_group" {
  #source      = "../terraform-os-security-group"
  source               = "github.com/dinivas/terraform-openstack-security-group"
  name                 = "${var.project_name}-common"
  description          = "${format("%s common security group", var.project_name)}"
  delete_default_rules = "false"
  rules                = "${var.common_security_group_rules}"
}

## Allow all ingress between instance of same security group
resource "openstack_networking_secgroup_rule_v2" "common_remote_security_group" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = "${tostring(module.common_security_group.id)}"
  security_group_id = "${tostring(module.common_security_group.id)}"
}

# ************************** Keypair setup*******************************************

module "bastion_generated_keypair" {
  #source           = "../terraform-os-keypair"
  source           = "github.com/dinivas/terraform-openstack-keypair"
  name             = "${var.project_name}-bastion-generated-keypair"
  generate_ssh_key = true
}

resource "local_file" "bastion_private_key" {
  content  = "${module.bastion_generated_keypair.private_key}"
  filename = "${var.bastion_private_key_output_directory != "" ? var.bastion_private_key_output_directory : path.cwd}/${var.project_name}-bastion.key"
  file_permission = "0400"
}

module "project_generated_keypair" {
  #source           = "../terraform-os-keypair"
  source           = "github.com/dinivas/terraform-openstack-keypair"
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
