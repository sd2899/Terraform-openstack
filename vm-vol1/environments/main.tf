module "ubuntu_vms" {
  source       = "/home/tera/openstack/terraform/vm-vol11/modules/vm"
  os_name      = "ubuntu"
  image_name   = "Ubuntu-desktop-24.02"
  flavor_name  = ["m1.medium", "m1.medium"] # Different flavors for 2 VMs
  network_id   = var.network_id
  keypair_name = var.keypair_name
  vm_count     = 2
  volume_size  = 20
}

module "centos_vms" {
  source       = "/home/tera/openstack/terraform/vm-vol11/modules/vm"
  os_name      = "xubuntu"
  image_name   = "xubuntu-ssh"
  flavor_name  = "m1.medium" # Single VM
  network_id   = var.network_id
  keypair_name = var.keypair_name
  vm_count     = 1
  volume_size  = 20
}

# Save outputs to JSON
resource "local_file" "terraform_output" {
  content = jsonencode({
    ubuntu_vm_names = module.ubuntu_vms.vm_names
    #ubuntu_vm_ips   = module.ubuntu_vms.vm_ips
    centos_vm_names = module.centos_vms.vm_names
    #centos_vm_ips   = module.centos_vms.vm_ips
  })
  filename = "/home/tera/openstack/terraform/vm-vol11/outputs/terraform-output.json"
}
