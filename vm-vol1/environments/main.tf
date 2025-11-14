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

locals {
  combined_outputs = {
    ubuntu_instances = module.ubuntu_vms.instance_info
    ubuntu_fips      = module.ubuntu_vms.floating_ips
    centos_instances = module.centos_vms.instance_info
    centos_fips      = module.centos_vms.floating_ips
  }
}

# Optional local_file (recommended if you have local provider)
resource "local_file" "terraform_output" {
  content  = jsonencode(local.combined_outputs)
  filename = "/home/tera/openstack/terraform/vm-vol11/outputs/terraform-output.json"
}
