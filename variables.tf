variable "project_name" {
  type        = "string"
  description = "The name of the project. it will be used as preffix for most resource"
}

variable "project_description" {
  type        = "string"
  description = "The description of the project."
  default     = ""
}

variable "bastion_ssh_user" {
  type        = "string"
  description = "The user to use for provisioning over SSH."
}

variable "bastion_private_key_output_directory" {
  type        = "string"
  description = "The directory where the Bastion private key will be generated."
  default     = ""
}

variable "floating_ip_pool" {
  type        = "string"
  description = "Pool name to retrieve floating ip"
  default     = "public"
}
variable "bastion_existing_floating_ip_to_use" {
  type        = "string"
  description = "Available floating ip to associate to bastion host"
  default     = ""
}

variable "bastion_image_name" {
  type        = "string"
  description = "The bastion compute image name."
}

variable "bastion_compute_flavor_name" {
  type        = "string"
  description = "The bastion compute flavor name."
}

variable "public_router_name" {
  type        = "string"
  description = "The router (gateway) to used."
  default     = ""
}

variable "bastion_security_group_rules" {
  default = [
    {
      direction        = "ingress"
      ethertype        = "IPv4"
      protocol         = "tcp"
      port_range_min   = 22
      port_range_max   = 22
      remote_ip_prefix = "0.0.0.0/0"
    },
    {
      direction        = "ingress"
      ethertype        = "IPv4"
      protocol         = "icmp"
      port_range_min   = 0
      port_range_max   = 0
      remote_ip_prefix = "0.0.0.0/0"
    },
  ]
}
