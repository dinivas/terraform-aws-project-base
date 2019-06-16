output "bastion_floating_ip" {
  description = "The floating ip bind to bastion"
  value       = ["${module.shepherdcloud_base.bastion_floating_ip}"]
}

output "project_router_id" {
  description = "The project router id"
  value       = "${module.shepherdcloud_base.project_router_id}"
}

output "bastion_private_key_file" {
  value       = "${module.shepherdcloud_base.bastion_private_key_file}"
  description = "The private Key (generated) to access bastion"
}

output "project_keypair" {
  value       = "${module.shepherdcloud_base.project_keypair_name}"
  description = "Default keypair used for project hosts"
}
