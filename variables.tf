variable "project_name" {
  type        = "string"
  description = "The name of the project. it will be used as preffix for most resource"
}

variable "project_description" {
  type        = "string"
  description = "The description of the project."
  default     = ""
}

variable "project_root_domain" {
  type        = "string"
  description = "The root Domain (DNS) used for this project"
}

variable "project_availability_zone" {
  type        = "string"
  description = "The project availability zone."
  default     = "null"
}

variable "mgmt_subnet_cidr" {
  type    = "string"
  default = "10.10.11.0/24"
}

variable "mgmt_subnet_dhcp_allocation_start" {
  type = "string"
}

variable "mgmt_subnet_dhcp_allocation_end" {
  type = "string"
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

variable "external_network" {
  type        = "string"
  description = "The external network name"
  default     = "public"
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

variable "common_security_group_rules" {
  type        = list(map(any))
  description = "Common security group rules"
  default     = []
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
      remote_ip_prefix = "0.0.0.0/0"
    },
  ]
}

variable "proxy_security_group_rules" {
  default = [
    {
      direction        = "ingress"
      ethertype        = "IPv4"
      protocol         = "tcp"
      port_range_min   = 80
      port_range_max   = 80
      remote_ip_prefix = "0.0.0.0/0"
    },
    {
      direction        = "ingress"
      ethertype        = "IPv4"
      protocol         = "tcp"
      port_range_min   = 443
      port_range_max   = 443
      remote_ip_prefix = "0.0.0.0/0"
    },
    {
      direction        = "ingress"
      ethertype        = "IPv4"
      protocol         = "icmp"
      remote_ip_prefix = "0.0.0.0/0"
    }
  ]
}

variable "prometheus_security_group_rules" {
  default = []
}

variable "metadata" {
  description = "A map of metadata to add to all resources supporting it."
  default     = {}
}

variable enable_proxy {
  type    = "string"
  default = "1"
}

variable enable_prometheus {
  type    = "string"
  default = "0"
}

variable enable_logging_graylog {
  type    = "string"
  default = "0"
}

variable enable_logging_kibana {
  type    = "string"
  default = "0"
}

variable "proxy_image_name" {
  type        = "string"
  description = "The proxy compute image name."
}

variable "proxy_compute_flavor_name" {
  type        = "string"
  description = "The proxy compute flavor name."
}

variable "prometheus_image_name" {
  type        = "string"
  description = "The prometheus compute image name."
}

variable "prometheus_compute_flavor_name" {
  type        = "string"
  description = "The prometheus compute flavor name."
}

# Project Consul variables

variable "project_consul_enable" {
  type    = "string"
  default = "0"
}

variable "project_consul_domain" {
  type        = "string"
  description = "The domain name to use for the Consul cluster"
}

variable "project_consul_datacenter" {
  type        = "string"
  description = "The datacenter name for the consul cluster"
}

variable "project_consul_floating_ip_pool" {
  type        = "string"
  description = "Pool name to retrieve floating ip"
  default     = ""
}

variable "project_consul_server_count" {
  default = "1"
}

variable "project_consul_client_count" {
  default = "1"
}

variable "project_consul_server_image_name" {
  type        = "string"
  description = "The compute image name used for Consul server."
  default     = "Dinivas Base"
}

variable "project_consul_server_flavor_name" {
  type        = "string"
  description = "The compute flavor name used for Consul server."
  default     = "dinivas.medium"
}

variable "project_consul_client_image_name" {
  type        = "string"
  description = "The compute image name used for Consul client."
  default     = "Dinivas Base"
}

variable "project_consul_client_flavor_name" {
  type        = "string"
  description = "The compute flavor name used for Consul client."
  default     = "dinivas.medium"
}

# Project Keycloak variables

variable "project_keycloak_scheme" {
  type    = "string"
  description = "Used by application that need to connect to Keycloak"
  default = "http"
}

variable "project_keycloak_host" {
  type        = "string"
  description = "Used by application that need to connect to Keycloak"
}

# Auth variables used by consul

variable "os_auth_domain_name" {
  type    = "string"
  default = "default"
}

variable "os_auth_username" {
  type = "string"
}

variable "os_auth_password" {
  type = "string"
}

variable "os_auth_url" {
  type = "string"
}

variable "os_project_id" {
  type = "string"
}
