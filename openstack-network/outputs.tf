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
