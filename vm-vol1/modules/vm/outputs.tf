output "instance_info" {
  description = "Instance details"
  value = {
    for instance in openstack_compute_instance_v2.vms :
    instance.name => {
      id         = instance.id
      name       = instance.name
      private_ip = instance.network[0].fixed_ip_v4
    }
  }
}

output "floating_ips" {
  description = "Floating IPs for instances"
  value = {
    for idx, fip in openstack_networking_floatingip_v2.fips :
    openstack_compute_instance_v2.vms[idx].name => fip.address
  }
}
