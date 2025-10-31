module "dev_vm" {
  source            = "../../modules/vms"
  name              = "dev-instance"
  vms               = var.vms
  #images            = ["Ubuntu-desktop-24.02", "xubuntu-ssh"]
  #flavor            = "m1.medium"
  #volume_size       = var.volume_size
  public_network_name   = var.public_network_name
  private_network_name  = var.private_network_name
  keypair_name      = var.keypair_name
  assign_floating_ip = true
  user_data         = file("../../scripts/user_data.sh")
}

resource "null_resource" "save_outputs" {
  provisioner "local-exec" {
    command = "mkdir -p ./output && terraform output -json > ./output/terraform-output.json"
  }

  triggers = {
    always_run = timestamp()
  }
}
