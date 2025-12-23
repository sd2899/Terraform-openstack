output "router_ids" {
  value = local.router_ids
}

output "network_ids" {
  value = {
    for k, v in openstack_networking_network_v2.networks :
    k => v.id
  }
}

output "subnet_ids" {
  value = {
    for k, v in openstack_networking_subnet_v2.subnets :
    k => v.id
  }
}

output "subnets" {
  value = {
    for k, s in openstack_networking_subnet_v2.subnets :
    k => {
      id            = s.id
      cidr          = s.cidr
      gateway_ip    = s.gateway_ip
      network_id    = s.network_id
#      network_name  = s.network_name
    }
  }
}

output "routers" {
  value = {
    for k, r in openstack_networking_router_v2.routers :
    k => {
      id               = r.id
      name             = r.name
      external_network = r.external_network_id

      interfaces = [
        for iface in openstack_networking_router_interface_v2.interfaces :
        {
          subnet_id = iface.subnet_id
          port_id   = iface.port_id
        }
        if iface.router_id == r.id
      ]
    }
  }
}
