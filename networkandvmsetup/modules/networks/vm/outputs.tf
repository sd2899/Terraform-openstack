output "vm_ids" {
  value = {
    for k, v in openstack_compute_instance_v2.vms : k => v.id
  }
}

output "floating_ips" {
  value = {
    for k, v in openstack_networking_floatingip_v2.fips : k => v.address
  }
}

output "vms" {
  value = {
    for k, vm in openstack_compute_instance_v2.vms :
    k => {
      id     = vm.id
      name   = vm.name
      flavor = vm.flavor_name

      ports = [
        for p in openstack_networking_port_v2.ports :
        {
          id              = p.id
          network_id      = p.network_id
          #fixed_ips       = p.fixed_ips
          mac_address     = p.mac_address
          security_groups = p.security_group_ids
        }
        if p.device_id == vm.id
      ]
    }
  }
}
