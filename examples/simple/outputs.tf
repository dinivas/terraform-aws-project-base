output "bastion_floating_ip" {
  description = "The floating ip bind to bastion"
  value       = "${module.dinivas_project_base.bastion_floating_ip}"
}

# output "proxy_floating_ip" {
#   description = "The floating ip bind to proxy"
#   value       = "${module.dinivas_project_base.proxy_floating_ip}"
# }

output "bastion_private_key" {
  value       = "${module.dinivas_project_base.bastion_private_key}"
  description = "The private Key (generated) to access bastion"
  sensitive   = true
}

output "bastion_private_key_file" {
  value       = "${module.dinivas_project_base.bastion_private_key_file}"
  description = "The private Key file(generated) to access bastion"
}

output "project_private_key" {
  value       = "${module.dinivas_project_base.project_private_key}"
  description = "The private Key to access project instances"
  sensitive   = true
}

output "project_keypair" {
  value       = "${module.dinivas_project_base.project_keypair_name}"
  description = "Default keypair used for project hosts"
}

output "project_mgmt_network_name" {
  value       = "${module.dinivas_project_base.mgmt_network_name}"
  description = "Project management network"
}

# output "project_consul_server_instance_ids" {
#   value = "${module.dinivas_project_base.consul_server_instance_ids}"
# }

# output "project_consul_client_instance_ids" {
#   value = "${module.dinivas_project_base.consul_client_instance_ids}"
# }
