# Project default Consul definition

# Consul servers definitions
data "template_file" "consul_server_user_data" {
  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "aws"
    project_name              = var.project_name
    consul_agent_mode         = "server"
    consul_server_count       = "${var.project_consul_server_count}"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    aws_region                = var.aws_region
    aws_access_key_id         = var.aws_access_key_id
    aws_secret_access_key     = var.aws_secret_access_key
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

resource "aws_instance" "consul_server" {
  count = var.project_consul_server_count * var.project_consul_enable

  depends_on = [aws_instance.bastion, aws_eip_association.bastion_floatingip_associate]

  ami                    = var.project_consul_server_image_name
  instance_type          = var.project_consul_server_flavor_name
  key_name               = aws_key_pair.project_ssh_key.key_name
  availability_zone      = var.project_availability_zone
  user_data              = data.template_file.consul_server_user_data.rendered
  vpc_security_group_ids = [aws_security_group.private_subnet.id]

  subnet_id = aws_subnet.private.id
  tags = {
    Name = format("%s-%s-%s", var.project_name, "consul-server", count.index)
  }

}

// Conditional floating ip on the first Consul server
resource "aws_eip" "consul_cluster_floatingip" {
  count = var.project_consul_floating_ip_pool != "" ? var.project_consul_enable * 1 : 0
}

resource "aws_eip_association" "consul_cluster_floatingip_associate" {
  count = var.project_consul_floating_ip_pool != "" ? var.project_consul_enable * 1 : 0

  allocation_id = aws_eip.consul_cluster_floatingip[count.index].id
  instance_id   = aws_instance.consul_server[count.index].id
}

# Consul client definitions

data "template_file" "consul_client_user_data" {
  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "aws"
    project_name              = var.project_name
    consul_agent_mode         = "client"
    consul_cluster_domain     = "${var.project_consul_domain}"
    consul_cluster_datacenter = "${var.project_consul_datacenter}"
    consul_cluster_name       = "${var.project_name}-consul"
    aws_region                = var.aws_region
    aws_access_key_id         = var.aws_access_key_id
    aws_secret_access_key     = var.aws_secret_access_key
    enable_logging_graylog    = var.enable_logging_graylog

    pre_configure_script     = ""
    custom_write_files_block = ""
    post_configure_script    = ""
  }
}

resource "aws_instance" "consul_client" {
  count = var.project_consul_client_count * var.project_consul_enable

  depends_on = [aws_instance.bastion, aws_eip_association.bastion_floatingip_associate]

  ami                    = var.project_consul_client_image_name
  instance_type          = var.project_consul_client_flavor_name
  key_name               = aws_key_pair.project_ssh_key.key_name
  availability_zone      = var.project_availability_zone
  user_data              = data.template_file.consul_client_user_data.rendered
  vpc_security_group_ids = [aws_security_group.private_subnet.id]

  subnet_id = aws_subnet.private.id
  tags = {
    Name = format("%s-%s-%s", var.project_name, "consul-client", count.index)
  }

}

resource "null_resource" "consul_client_leave" {
  count = var.project_consul_client_count * var.project_consul_enable

  triggers = {
    bastion_private_key       = tls_private_key.bastion.private_key_pem
    consul_client_private_key = tls_private_key.project.private_key_pem
    bastion_floating_ip       = aws_eip.bastion_floatingip.public_ip
    private_ip                = aws_instance.consul_client[count.index].public_ip
    bastion_ssh_user          = var.bastion_ssh_user
  }

  connection {
    type        = "ssh"
    user        = self.triggers.bastion_ssh_user
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

  depends_on = [aws_eip_association.bastion_floatingip_associate]
}
