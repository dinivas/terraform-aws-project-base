resource "digitalocean_tag" "project" {
  name = var.project_name
}
# ************************** Networks setup ************************************

## Management network
module "mgmt_network" {
  source = "../terraform-digitalocean-network/"
  #source              = "github.com/dinivas/terraform-openstack-network"
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

locals {
  bastion_private_key_filename = "${var.bastion_private_key_output_directory != "" ? var.bastion_private_key_output_directory : path.cwd}/${var.project_name}-bastion.key"
  bastion_public_key_filename  = "${var.bastion_private_key_output_directory != "" ? var.bastion_private_key_output_directory : path.cwd}/${var.project_name}-bastion.pub"
  project_private_key_filename = "${var.project_private_key_output_directory != "" ? var.project_private_key_output_directory : path.cwd}/${var.project_name}-project.key"
  project_public_key_filename  = "${var.project_private_key_output_directory != "" ? var.project_private_key_output_directory : path.cwd}/${var.project_name}-project.pub"
}

resource "local_file" "bastion_private_key" {
  content  = tls_private_key.bastion.private_key_pem
  filename = local.bastion_private_key_filename
  #file_permission = "0400"
}
resource "local_file" "bastion_public_key" {
  content  = tls_private_key.bastion.public_key_openssh
  filename = local.bastion_public_key_filename
  #file_permission = "0400"
}

resource "local_file" "project_private_key" {
  content  = tls_private_key.project.private_key_pem
  filename = local.project_private_key_filename
  #file_permission = "0400"
}
resource "local_file" "project_public_key" {
  content  = tls_private_key.project.public_key_openssh
  filename = local.project_public_key_filename
  #file_permission = "0400"
}

module "bastion_ssh_key" {
  source = "../terraform-digitalocean-keypair"
  #source           = "github.com/dinivas/terraform-openstack-keypair"
  name       = "${var.project_name}-bastion-keypair"
  public_key = tls_private_key.bastion.public_key_openssh
}

module "project_ssh_key" {
  source = "../terraform-digitalocean-keypair"
  #source           = "github.com/dinivas/terraform-openstack-keypair"
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
