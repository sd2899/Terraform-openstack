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
variable "name" {}
#variable "flavor" {}
#variable "images" {
#  type = list(string)
#}
#variable "volume_size" {}
variable "public_network_name" {}
variable "private_network_name" {}
variable "keypair_name" {}
variable "assign_floating_ip" {
  default = false
}
variable "user_data" {
  default = ""
}


#variable "name" {}
#variable "image" {}
#variable "flavor" {}
#variable "public_network_name" {}
#variable "private_network_name" {}
#variable "keypair_name" {}
#variable "volume_size_gb" { default = 20 }
#variable "assign_floating_ip" { default = true }
#variable "user_data" { default = "" }
#variable "volume_size" {}
