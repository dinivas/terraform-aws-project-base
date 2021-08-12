output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "bastion_private_key" {
  value       = tls_private_key.bastion.private_key_pem
  description = "The generated private Key to access bastion"
  sensitive   = true
}

output "project_private_key" {
  value       = tls_private_key.project.private_key_pem
  description = "The generated private Key to access project instance"
  sensitive   = true
}

output "mgmt_network_id" {
  value       = aws_vpc.this.id
  description = "The id of the Mgmt Network being created"
}
output "mgmt_network_name" {
  value       = aws_vpc.this.id
  description = "The name of the Mgmt Network being created"
}

output "bastion_floating_ip" {
  value       = local.bastion_floating_ip
  description = "The floating ip bind to bastion"
}

output "proxy_floating_ip" {
  value       = aws_eip_association.proxy_floatingip_associate.0.public_ip
  description = "The floating ip bind to proxy"
}

output "project_keypair_name" {
  value       = aws_key_pair.project_ssh_key.key_name
  description = "Default keypair used for project hosts"
}


output "consul_server_instance_ids" {
  value = aws_instance.consul_server.*.id
}

output "consul_client_instance_ids" {
  value = aws_instance.consul_client.*.id
}

output "ssh_via_bastion_config" {
  value = {
    host_private_key    = tls_private_key.project.private_key_pem
    bastion_host        = local.bastion_floating_ip
    bastion_private_key = tls_private_key.bastion.private_key_pem
  }
  sensitive   = true
}
