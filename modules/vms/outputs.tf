#output "vm_names" {
#  value = [for vm in openstack_compute_instance_v2.vms : vm.name]
#}

#output "floating_ips" {
#  value = [for fip in openstack_networking_floatingip_v2.fips : fip.address]
#}

output "vm_ips" {
  value = {
    for k, v in openstack_compute_instance_v2.instances :
    k => {
      name        = v.name
      private_ip  = v.network[0].fixed_ip_v4
      public_ip   = try(openstack_networking_floatingip_v2.fips[k].address, null)
      volume_name = openstack_blockstorage_volume_v3.boot_volumes[k].name
    }
  }
}


#output "vm_info" {
#  value = {
#    for k, vm in openstack_compute_instance_v2.instances :
#    k => {
#      name        = vm.name
#      private_ip  = vm.network[0].fixed_ip_v4
#      floating_ip = try(openstack_networking_floatingip_v2.fip[k].address, null)
#    }
#  }
#}


#output "vm_name" {
#  value = openstack_compute_instance_v2.vms.name
#}

#output "floating_ip" {
#  value = openstack_networking_floatingip_v2.fips.address
#}

#output "volume_id" {
#  value = openstack_blockstorage_volume_v3.volume.id
#}
