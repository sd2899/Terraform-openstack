output "all_vm_ips" {
  value = {
    ubuntu = module.ubuntu_vms.all_vm_ips
    centos = module.centos_vms.all_vm_ips
  }
}
