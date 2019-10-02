output "bastion_floating_ip" {
  description = "The floating ip bind to bastion"
  value       = "${module.dinivas_project_base.bastion_floating_ip}"
}

output "proxy_floating_ip" {
  description = "The floating ip bind to proxy"
  value       = "${module.dinivas_project_base.proxy_floating_ip}"
}

output "project_router_id" {
  description = "The project router id"
  value       = "${module.dinivas_project_base.project_router_id}"
}

output "bastion_private_key" {
  value       = "${module.dinivas_project_base.bastion_private_key}"
  description = "The private Key (generated) to access bastion"
  sensitive   = true
}

output "bastion_private_key_file" {
  value       = "${module.dinivas_project_base.bastion_private_key_file}"
  description = "The private Key file(generated) to access bastion"
}

output "project_keypair" {
  value       = "${module.dinivas_project_base.project_keypair_name}"
  description = "Default keypair used for project hosts"
}

output "project_mgmt_network_names" {
  value       = "${module.dinivas_project_base.mgmt_network_name}"
  description = "Project management network"
}

output "project_mgmt_subnet_names" {
  value       = "${module.dinivas_project_base.mgmt_subnet_names}"
  description = "Project management network"
}

output "project_consul_server_instance_ids" {
  value = "${module.dinivas_project_base.consul_server_instance_ids}"
}

output "project_consul_client_instance_ids" {
  value = "${module.dinivas_project_base.consul_client_instance_ids}"
}

output "project_consul_server_network_fixed_ip_v4" {
  value = "${module.dinivas_project_base.consul_server_network_fixed_ip_v4}"
}

output "project_consul_client_network_fixed_ip_v4" {
  value = "${module.dinivas_project_base.consul_client_network_fixed_ip_v4}"
}
