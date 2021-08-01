resource "digitalocean_tag" "project" {
  name = var.project_name
}
# ************************** Networks setup ************************************

## Management network
module "mgmt_network" {
  #source = "../terraform-digitalocean-network/"
  source              = "github.com/dinivas/terraform-digitalocean-network"
  vpc_name        = "${var.project_name}-mgmt"
  vpc_description = var.project_description
  vpc_ip_range    = var.mgmt_subnet_cidr
  vpc_region      = var.project_availability_zone

}

# ************************** Router setup *****************************************

// Not needed in DigitalOcean

# ************************** Security Groups (Firewall rules) setup *********************************

# Common
#module "common_firewall_rules" {
#  source = "../terraform-digitalocean-firewall"
#  #source               = "github.com/dinivas/terraform-openstack-security-group"
#  name           = "${var.project_name}-common"
#  inbound_rules  = var.common_firewall_inbound_rules
#  outbound_rules = var.common_firewall_outbound_rules
#}

# ************************** Keypair setup*******************************************

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
}

resource "tls_private_key" "project" {
  algorithm = "RSA"
}

module "bastion_ssh_key" {
  #source = "../terraform-digitalocean-keypair"
  source           = "github.com/dinivas/terraform-digitalocean-keypair"
  name       = "${var.project_name}-bastion-keypair"
  public_key = tls_private_key.bastion.public_key_openssh
}

module "project_ssh_key" {
  #source = "../terraform-digitalocean-keypair"
  source           = "github.com/dinivas/terraform-digitalocean-keypair"
  name       = "${var.project_name}-project-keypair"
  public_key = tls_private_key.project.public_key_openssh
}

# ************************** Floating Ips *******************************************

## Bastion

resource "digitalocean_floating_ip" "bastion_floatingip" {
  region = var.project_availability_zone
}

locals {
  bastion_floating_ip = digitalocean_floating_ip.bastion_floatingip.ip_address
}

data "http" "generic_user_data_template" {
  url = var.generic_user_data_file_url
}
