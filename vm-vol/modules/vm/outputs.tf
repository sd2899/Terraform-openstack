output "all_vm_info" {
  value = {
    for name in var.vm_names : name => {
      internal_ip = openstack_compute_instance_v2.instances[name].access_ip_v4
      floating_ip = openstack_networking_floatingip_v2.fips[name].address
    }
  }
}
