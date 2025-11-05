module "ubuntu_vms" {
  source          = "/home/tera/openstack/terraform/vm-vol/modules/vm"
  os_name         = "ubuntu"
  image_id        = var.ubuntu_image_id
  volume_size     = 20
  flavor          = var.flavor
  keypair         = var.keypair
  external_network = var.external_network
  security_groups = ["default"]
  network_name    = var.network_name
  vm_names        = ["ubuntu-web1", "ubuntu-web2"]
}

module "centos_vms" {
  source          = "/home/tera/openstack/terraform/vm-vol/modules/vm"
  os_name         = "centos"
  image_id        = var.centos_image_id
  volume_size     = 20
  flavor          = var.flavor
  keypair         = var.keypair
  external_network = var.external_network
  security_groups = ["default"]
  network_name    = var.network_name
  vm_names        = ["centos-app1"]
}

# ─────────────────────────────
# Output both sets
# ─────────────────────────────
#output "all_vm_ips" {
#  value = {
#    ubuntu = module.ubuntu_vms.vm_ips
#    centos = module.centos_vms.vm_ips
#  }
#}


output "all_vm_info" {
  value = merge(module.ubuntu_vms.vm_info, module.centos_vms.vm_info)
}

resource "local_file" "vm_output" {
  content  = jsonencode(merge(module.ubuntu_vms.vm_info, module.centos_vms.vm_info))
  filename = "/home/tera/openstack/terraform/vm-vol/outputs/vm_info.json"
}
