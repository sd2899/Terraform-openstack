variable "os_name" {}
variable "image_id" {}
variable "volume_size" {}
variable "flavor" {}
variable "keypair" {}
variable "security_groups" {
  type    = list(string)
  default = ["default"]
}
variable "network_name" {}
variable "vm_names" {
  type = list(string)
}
