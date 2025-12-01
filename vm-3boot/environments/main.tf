############################
# NETWORK LOOKUPS
############################
data "openstack_networking_network_v2" "private" {
  name = var.network_name
}

data "openstack_networking_network_v2" "public" {
  name = var.external_network_name
}

############################
# CALL VM MODULE
############################
module "vmset" {
  source = "../modules/vms"

  environment            = var.environment
  network_name           = var.network_name
  external_network_name  = var.external_network_name

  default_keypair        = var.default_keypair
  default_user_data_file = var.default_user_data_file

  vms = var.vms
}

############################
# EXTRA ENV RESOURCES (Optional)
############################
# Example: Security groups, networks, monitoring, etc.
# (Left empty so you can expand as needed)
