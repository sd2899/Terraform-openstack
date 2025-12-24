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
  description = "VMs with all ports and IPs (fixed + DHCP)"
  value = {
    for vm_key, vm in openstack_compute_instance_v2.vms :
    vm_key => {
      id   = vm.id
      name = vm.name

      ports = [
        for p in openstack_networking_port_v2.ports :
        {
          port_id   = p.id
          mac       = p.mac_address
          network_id = p.network_id

          fixed_ips      = p.all_fixed_ips
#          port_ip        = length(p.fixed_ip) > 0 ? p.ip_address : null
          security_groups = p.security_group_ids
        }
        if p.device_id == vm.id
      ]
      floating_ip = try(
        openstack_compute_floatingip_associate_v2.assoc[vm_key].floating_ip,
        null
      )

    }
  }
}
