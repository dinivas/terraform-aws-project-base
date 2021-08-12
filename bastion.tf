# ************************** Compute (bastion) setup*********************************

data "template_file" "bastion_user_data" {
  template = data.http.generic_user_data_template.body

  vars = {
    cloud_provider            = "aws"
    project_name              = var.project_name
    consul_agent_mode         = "client"
    consul_cluster_domain     = var.project_consul_domain
    consul_cluster_datacenter = var.project_consul_datacenter
    consul_cluster_name       = "${var.project_name}-consul"
    aws_region                = var.aws_region
    aws_access_key_id         = var.aws_access_key_id
    aws_secret_access_key     = var.aws_secret_access_key
    enable_logging_graylog    = var.enable_logging_graylog

    pre_configure_script     = ""
    post_configure_script    = ""
    custom_write_files_block = ""
  }
}

resource "aws_instance" "bastion" {

  ami               = var.bastion_image_name
  instance_type     = var.bastion_compute_flavor_name
  key_name          = aws_key_pair.bastion_ssh_key.key_name
  availability_zone = var.project_availability_zone
  user_data         = data.template_file.bastion_user_data.rendered

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id, aws_security_group.common.id, aws_security_group.public_subnet.id]

  depends_on = [aws_internet_gateway.this]
  tags = {
    Name = format("%s-bastion", var.project_name)
  }
}

resource "null_resource" "provision_project_private_key_to_bastion" {
  triggers = {
    bastion_instance_id             = aws_instance.bastion.id
    bastion_floating_ip             = aws_eip.bastion_floatingip.public_ip
    bastion_floatingip_associate_id = aws_eip_association.bastion_floatingip_associate.id
    bastion_ssh_user                = var.bastion_ssh_user
  }
  provisioner "file" {
    content     = tls_private_key.project.private_key_pem
    destination = "~/.ssh/${var.project_name}.key"
    connection {
      type        = "ssh"
      host        = aws_eip.bastion_floatingip.public_ip
      user        = self.triggers.bastion_ssh_user
      private_key = tls_private_key.bastion.private_key_pem
    }
  }
  depends_on = [aws_eip.bastion_floatingip, aws_eip_association.bastion_floatingip_associate]
}

resource "aws_eip_association" "bastion_floatingip_associate" {
  allocation_id = aws_eip.bastion_floatingip.id
  instance_id   = aws_instance.bastion.id
}

# ***********************
