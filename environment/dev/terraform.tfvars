keypair_name   = "ubuntu"
public_network_name = "public1"
private_network_name = "demo"
#variable_size = 20

vms = {
  web1 = {
    name            = "test-1"
    flavor          = "m1.medium"
    image           = "xubuntu-ssh"
    #security_groups = ["default"]
    volume_size     = 20
  }
  web2 = {
    name            = "test-2"
    flavor          = "m1.medium"
    image           = "Ubuntu-desktop-24.02"
    #security_groups = ["default"]
    volume_size     = 20
  }
  web3 = {
    name            = "test-3"
    flavor          = "m1.medium"
    image           = "Ubuntu-desktop-24.02"
    #security_groups = ["default"]
    volume_size     = 20
  }
}
