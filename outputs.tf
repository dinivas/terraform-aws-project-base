output "bastion_instance_id" {
  value = digitalocean_droplet.bastion.id
}

output "bastion_private_key" {
  value       = tls_private_key.bastion.private_key_pem
  description = "The generated private Key to access bastion"
  sensitive   = true
}

output "bastion_private_key_file" {
  value       = local_file.bastion_private_key.filename
  description = "The private Key file (generated) to access bastion"
}

output "project_private_key" {
  value       = tls_private_key.project.private_key_pem
  description = "The generated private Key to access project instance"
  sensitive   = true
}

output "mgmt_network_id" {
  value       = module.mgmt_network.vpc_id
  description = "The id of the Mgmt Network being created"
}
output "mgmt_network_name" {
  value       = module.mgmt_network.vpc_name
  description = "The name of the Mgmt Network being created"
}

output "bastion_floating_ip" {
  value       = local.bastion_floating_ip
  description = "The floating ip bind to bastion"
}

output "proxy_floating_ip" {
  value       = digitalocean_floating_ip_assignment.proxy_floatingip_associate.0.ip_address
  description = "The floating ip bind to proxy"
}

output "project_keypair_name" {
  value       = module.project_ssh_key.name
  description = "Default keypair used for project hosts"
}


output "consul_server_instance_ids" {
  value = digitalocean_droplet.consul_server.*.id
}

output "consul_client_instance_ids" {
  value = digitalocean_droplet.consul_client.*.id
}

output "ssh_via_bastion_config" {
  value = {
    host_private_key    = tls_private_key.project.private_key_pem
    bastion_host        = local.bastion_floating_ip
    bastion_private_key = tls_private_key.bastion.private_key_pem
  }
  sensitive   = true
}
