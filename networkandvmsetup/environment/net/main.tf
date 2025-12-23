module "network" {
  source = "../../modules/network"

  external_network_name = var.external_network_name
  networks              = var.networks
}

module "vm" {
  source = "../../modules/network/vm"

  project_name = var.project_name
  domain_id    = var.domain_id

  external_network_name = var.external_network_name
  subnet_ids            = module.network.subnet_ids
  network_ids            = module.network.network_ids
  vms                   = var.vms
}
