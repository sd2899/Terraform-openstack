variable "keypair_name" {}
variable "public_network_name" {}
variable "private_network_name" {}
#variable "volume_size" {}
variable "vms" {
  description = "VM definitions map"
  type = map(object({
    name            = string
    flavor          = string
    image           = string
    #security_groups = list(string)
    volume_size     = number
  }))
}
