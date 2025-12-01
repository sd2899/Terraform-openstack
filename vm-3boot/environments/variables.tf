#####################################################
# AUTHENTICATION VARIABLES
#####################################################
variable "auth_url"         { type = string }
variable "user_name"        { type = string }
variable "password"         { type = string }
variable "domain_name"      { type = string }
variable "project_name"     { type = string }
variable "region"           { type = string }

#####################################################
# ENVIRONMENT SETTINGS
#####################################################
variable "environment" {
  type    = string
  default = "production"
}

#####################################################
# NETWORKS
#####################################################
variable "network_name" {
  type = string
}

variable "external_network_name" {
  type = string
}

#####################################################
# VM DEFAULTS
#####################################################
variable "default_keypair" {
  type = string
}

variable "default_user_data_file" {
  type    = string
  default = "${path.module}/../scripts/user_data.sh"
}

#####################################################
# VM LIST (passed to module)
#####################################################
variable "vms" {
  description = "Complete VM specifications"
  type = map(object({
    name        = string
    flavor      = string
    image       = optional(string)
    keypair     = optional(string)
    security_groups = list(string)

    boot_volume_id  = optional(string)
    boot_snapshot_id = optional(string)
    source_volume_id = optional(string)
    boot_volume_size = optional(number)

    data_volumes = optional(list(object({
      size        = number
      device      = optional(string)
      volume_type = optional(string)
      description = optional(string)
    })))

    assign_fip = optional(bool)
    user_data_file = optional(string)
    delete_boot_volume_on_termination = optional(bool)
  }))
}
