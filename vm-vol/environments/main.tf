module "ubuntu_vms" {
  source          = "/home/tera/openstack/terraform/vm-vol/modules/vm"
  os_name         = "ubuntu"
  image_id        = var.ubuntu_image_id
  volume_size     = 20
  flavor          = var.flavor
  keypair         = var.keypair
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


#resource "null_resource" "save_outputs" {
#  provisioner "local-exec" {
#    command = "mkdir -p /home/tera/openstack/terraform/vm-vol/output && terraform output -json > /home/tera/openstack/terraform/vm-vol/output/terraform-output.json"
#  }

#  triggers = {
#    always_run = timestamp()
#  }
#}

resource "null_resource" "save_outputs" {
  provisioner "local-exec" {
    command = "mkdir -p ./output && terraform output -json > ./output/terraform-output.json"
  }

  triggers = {
    always_run = timestamp()
  }
}
