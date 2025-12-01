output "vm_private_ips" {
  value = module.vmset.vm_ips
}

output "vm_floating_ips" {
  value = module.vmset.floating_ips
}
