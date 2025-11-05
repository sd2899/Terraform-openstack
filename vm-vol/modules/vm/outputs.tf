output "all_vm_ips" {
  value = { for name, vm in openstack_compute_instance_v2.instances : name => vm.access_ip_v4 }
}
