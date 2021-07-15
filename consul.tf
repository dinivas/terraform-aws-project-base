# Project default Consul definition

# Consul servers definitions
data "template_file" "consul_server_user_data" {
  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digitalocean"
    project_name              = var.project_name
    consul_agent_mode         = "server"
    consul_server_count       = "${var.project_consul_server_count}"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.project_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.enable_logging_graylog

    pre_configure_script     = ""
    custom_write_files_block = "${data.template_file.consul_server_user_data_write_files.rendered}"
    post_configure_script    = ""
  }
}

data "template_file" "consul_server_user_data_write_files" {
  template = file("${path.module}/templates/consul-server-user-data.tpl")

  vars = {
    consul_cluster_name = "${var.project_name}-consul"
  }
}

resource "digitalocean_droplet" "consul_server" {
  count = var.project_consul_server_count * var.project_consul_enable

  depends_on = [digitalocean_droplet.bastion, digitalocean_floating_ip_assignment.bastion_floatingip_associate]

  name               = format("%s-%s-%s", var.project_name, "consul-server", count.index)
  image              = var.project_consul_server_image_name
  size               = var.project_consul_server_flavor_name
  ssh_keys           = [module.project_ssh_key.id]
  region             = var.project_availability_zone
  vpc_uuid           = module.mgmt_network.vpc_id
  user_data          = data.template_file.consul_server_user_data.rendered
  tags               = concat([digitalocean_tag.project.name], split(",", format("consul_cluster_name_%s-%s,project_%s", var.project_name, "consul", var.project_name)))
  private_networking = true

}

// Conditional floating ip on the first Consul server
resource "digitalocean_floating_ip" "consul_cluster_floatingip" {
  count = var.project_consul_floating_ip_pool != "" ? var.project_consul_enable * 1 : 0

  region = var.project_availability_zone
}

resource "digitalocean_floating_ip_assignment" "consul_cluster_floatingip_associate" {
  count = var.project_consul_floating_ip_pool != "" ? var.project_consul_enable * 1 : 0

  ip_address = digitalocean_floating_ip.consul_cluster_floatingip[count.index].ip_address
  droplet_id = digitalocean_droplet.consul_server[count.index].id
}

# Consul client definitions

data "template_file" "consul_client_user_data" {
  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "digitalocean"
    project_name              = var.project_name
    consul_agent_mode         = "client"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    do_region                 = var.project_availability_zone
    do_api_token              = var.do_api_token
    enable_logging_graylog    = var.enable_logging_graylog

    pre_configure_script     = ""
    custom_write_files_block = ""
    post_configure_script    = ""
  }
}

resource "digitalocean_droplet" "consul_client" {
  count = var.project_consul_client_count * var.project_consul_enable

  depends_on = [digitalocean_droplet.bastion, digitalocean_floating_ip_assignment.bastion_floatingip_associate]

  name               = format("%s-%s-%s", var.project_name, "consul-client", count.index)
  image              = var.project_consul_client_image_name
  size               = var.project_consul_client_flavor_name
  ssh_keys           = [module.project_ssh_key.id]
  region             = var.project_availability_zone
  vpc_uuid           = module.mgmt_network.vpc_id
  user_data          = data.template_file.consul_client_user_data.rendered
  tags               = concat([digitalocean_tag.project.name], split(",", format("consul_cluster_name_%s-%s,project_%s", var.project_name, "consul", var.project_name)))
  private_networking = true

}

resource "null_resource" "consul_client_leave" {
  count = var.project_consul_client_count * var.project_consul_enable

  triggers = {
    bastion_private_key       = tls_private_key.bastion.private_key_pem
    consul_client_private_key = tls_private_key.project.private_key_pem
    bastion_floating_ip       = local.bastion_floating_ip
    private_ip                = digitalocean_droplet.consul_client[count.index].ipv4_address_private
    bastion_ssh_user          = var.bastion_ssh_user
  }

  connection {
    type        = "ssh"
    user        = "root"
    port        = 22
    host        = self.triggers.private_ip
    private_key = self.triggers.consul_client_private_key
    agent       = false

    bastion_host        = self.triggers.bastion_floating_ip
    bastion_user        = self.triggers.bastion_ssh_user
    bastion_private_key = self.triggers.bastion_private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "consul leave",
    ]
    on_failure = continue
  }

}
