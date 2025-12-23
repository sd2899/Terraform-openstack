output "networks" {
  description = "Networks with subnets and CIDR details"
  value = {
    for net_name, net_id in module.network.network_ids :
    net_name => {
      id   = net_id

      subnets = {
        for subnet_name, subnet in module.network.subnets :
        subnet_name => {
          id      = subnet.id
          name    = subnet_name
          cidr    = subnet.cidr
          netmask = cidrnetmask(subnet.cidr)
          gateway = subnet.gateway_ip
        }
      }
    }
  }
}

output "subnets" {
  description = "All subnets with network mapping"
  value = {
    for name, subnet in module.network.subnets :
    name => {
      id        = subnet.id
      name      = name
      cidr      = subnet.cidr
      netmask  = cidrnetmask(subnet.cidr)
      gateway  = subnet.gateway_ip
    }
  }
}

output "routers" {
  description = "Routers with interfaces and external gateway"
  value = {
    for r_name, r in module.network.routers :
    r_name => {
      id   = r.id
      name = r_name

      external_gateway = {
        network = r.external_network
        ip      = r.external_fixed_ip
      }

      interfaces = [
        for iface in r.interfaces : {
          subnet_id = iface.subnet_id
          port_id   = iface.port_id
        }
      ]
    }
  }
}

output "vm" {
  description = "VMs with ports, IPs, security groups, volumes"
  value = {
    for vm_name, vm in module.vm.vms :
    vm_name => {
      id     = vm.id
      name   = vm.name
      flavor = vm.flavor

      ports = [
        for p in vm.ports : {
          port_id   = p.id
          mac       = p.mac_address
          secgroups = p.security_groups
        }
      ]

      floating_ip = try(vm.floating_ip, null)

    }
  }
}

resource "local_file" "env_outputs" {
  filename = "/home/jack/project/output/outputs.json"

  content = jsonencode({
   "networks" = {
    description = "Networks with subnets and CIDR details"
    value = {
      for net_name, net_id in module.network.network_ids :
      net_name => {
        id   = net_id

        subnets = {
          for subnet_name, subnet in module.network.subnets :
         subnet_name => {
            id      = subnet.id
            name    = subnet_name
            cidr    = subnet.cidr
            netmask = cidrnetmask(subnet.cidr)
            gateway = subnet.gateway_ip
          }
        }
      }
    }
  }

   "subnets" = {
    description = "All subnets with network mapping"
    value = {
      for name, subnet in module.network.subnets :
      name => {
        id        = subnet.id
        name      = name
        cidr      = subnet.cidr
        netmask  = cidrnetmask(subnet.cidr)
        gateway  = subnet.gateway_ip
      }
    }
  }

   "routers" = {
    description = "Routers with interfaces and external gateway"
    value = {
      for r_name, r in module.network.routers :
      r_name => {
        id   = r.id
        name = r_name

        external_gateway = {
          network = r.external_network
          ip      = r.external_fixed_ip
        }

        interfaces = [
          for iface in r.interfaces : {
            subnet_id = iface.subnet_id
            port_id   = iface.port_id
          }
        ]
      }
    }
  }

   "vm" = {
    description = "VMs with ports, IPs, security groups, volumes"
    value = {
      for vm_name, vm in module.vm.vms :
      vm_name => {
        id     = vm.id
        name   = vm.name
        flavor = vm.flavor

        ports = [
          for p in vm.ports : {
            port_id   = p.id
            mac       = p.mac_address
            secgroups = p.security_groups
          }
        ]

        floating_ip = try(vm.floating_ip, null)

      }
    }
  }

 })
}
