#output "vm_names" {
#  value = [for vm in openstack_compute_instance_v2.vms : vm.name]
#}

#output "floating_ips" {
#  value = [for fip in openstack_networking_floatingip_v2.fips : fip.address]
#}

output "instance_info" {
  description = "Instance details"
  value = {
    for name, instance in openstack_compute_instance_v2.instances :
    name => {
      id         = instance.id
      name       = instance.name
      private_ip = instance.network[0].fixed_ip_v4
    }
  }
}

output "floating_ips" {
  description = "Floating IPs for instances"
  value = {
    for name, fip in openstack_networking_floatingip_v2.fips :
    name => fip.address
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
