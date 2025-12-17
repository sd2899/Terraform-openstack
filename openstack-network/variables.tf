variable "external_network_name" {
  description = "External provider network"
  type        = string
}

variable "networks" {
  description = "Networks with optional router configuration"
  type = map(object({

    router = object({
      create            = bool
      name              = string
      use_existing      = bool
      shared_router     = bool
    })

    subnets = map(object({
      cidr    = string
      gateway = string
      dns     = list(string)
      dhcp    = bool
    }))
  }))
}
