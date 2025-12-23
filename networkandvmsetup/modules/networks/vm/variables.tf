variable "external_network_name" {
  type = string
}
variable "project_name" {}
variable "domain_id" {}

#variable "project_name" {
#  type        = string
#  description = "OpenStack project (tenant) name"
#}

#variable "domain_id" {
#  type        = string
#  description = "OpenStack domain ID (usually default)"
#}


variable "network_ids" {
  description = "Map of network name to network ID"
  type        = map(string)
}

variable "subnet_ids" {
  description = "Subnet IDs from network module"
  type        = map(string)
}

#variable "subnet_ids" {
#  type = map(string)
#}

variable "vms" {
  type = map(object({
    name            = string
    flavor          = string
    keypair         = string
    security_groups = list(string)
    #subnet_key      = string

    user_data_file  = optional(string)

    ports = list(object({
      network_key     = string
      subnet_key      = string
      security_groups = list(string)

      # OPTIONAL FIXED IP
      fixed_ip = optional(string)
    }))

    boot = object({
      type        = string   # image | volume | snapshot
      image       = optional(string)
      volume_id   = optional(string)
      snapshot_id = optional(string)
      # only for snapshot and volume
      size        = optional(number)
    })

    additional_volumes = optional(list(object({
      size        = number
      volume_type = optional(string)
    })), [])

    assign_fip = bool
  }))
}
