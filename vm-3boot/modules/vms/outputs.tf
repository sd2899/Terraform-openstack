output "vm_ips" {
  value = {
    for k, v in openstack_compute_instance_v2.vms :
    k => v.access_ip_v4
  }
}

output "floating_ips" {
  value = {
    for k, f in openstack_networking_floatingip_v2.fips :
    k => f.address
  }
}
