# ************************** Compute (bastion) setup*********************************

data "template_file" "bastion_user_data" {
  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digitalocean"
    project_name              = var.project_name
    consul_agent_mode         = "client"
    consul_cluster_domain     = var.project_consul_domain
    consul_cluster_datacenter = var.project_consul_datacenter
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.project_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.enable_logging_graylog

    pre_configure_script     = ""
    post_configure_script    = ""
    custom_write_files_block = ""
  }
}

module "bastion_firewall_rules" {
  #source = "../terraform-digitalocean-firewall"
  source        = "github.com/dinivas/terraform-digitalocean-firewall"
  name          = "${var.project_name}-common"
  inbound_rules = var.bastion_firewall_inbound_rules
}


resource "digitalocean_droplet" "bastion" {

  name               = "${var.project_name}-bastion"
  image              = var.bastion_image_name
  size               = var.bastion_compute_flavor_name
  ssh_keys           = [module.bastion_ssh_key.id]
  region             = var.project_availability_zone
  vpc_uuid           = module.mgmt_network.vpc_id
  user_data          = data.template_file.bastion_user_data.rendered
  tags               = concat([digitalocean_tag.project.name], split(",", format("consul_cluster_name_%s-%s,project_%s", var.project_name, "consul", var.project_name)))
  private_networking = true
}


resource "null_resource" "provision_project_private_key_to_bastion" {
  triggers = {
    bastion_instance_id    = "${digitalocean_droplet.bastion.id}"
    bastion_floating_ip_id = "${digitalocean_floating_ip_assignment.bastion_floatingip_associate.droplet_id}"
  }

  provisioner "file" {
    content     = tls_private_key.project.private_key_pem
    destination = "~/.ssh/${var.project_name}.key"

    connection {
      type        = "ssh"
      host        = local.bastion_floating_ip
      user        = var.bastion_ssh_user
      private_key = tls_private_key.bastion.private_key_pem
    }
  }
}

resource "digitalocean_floating_ip_assignment" "bastion_floatingip_associate" {
  ip_address = local.bastion_floating_ip
  droplet_id = digitalocean_droplet.bastion.id
}

# ***********************
