variable "os_name" {
  description = "Name of the operating system (e.g., ubuntu, centos)"
  type        = string
}

variable "image_name" {
  description = "Name of the image in OpenStack"
  type        = string
}

variable "flavor_name" {
  description = "A single flavor name or a list of flavors for each VM"
  type        = any
}

variable "network_id" {
  description = "OpenStack network ID to attach VMs"
  type        = string
}

variable "keypair_name" {
  description = "Name of the OpenStack keypair"
  type        = string
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "volume_size" {
  description = "Base volume size in GB"
  type        = number
  default     = 20
}
