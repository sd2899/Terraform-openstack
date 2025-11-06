#output "all_vm_ips" {
#  value = openstack_networking_floatingip_v2.fips[*].address
#}

output "all_vm_names" {
  value = openstack_compute_instance_v2.vms[*].name
}
