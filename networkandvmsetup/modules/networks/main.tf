########################################
# External Provider Network
########################################
data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

########################################
# Routers (create or use existing)
########################################
resource "openstack_networking_router_v2" "routers" {
  for_each = {
    for k, v in var.networks :
    k => v
    if v.router.create
  }

  name                = each.value.router.name
  external_network_id = data.openstack_networking_network_v2.external.id
}

data "openstack_networking_router_v2" "existing_routers" {
  for_each = {
    for k, v in var.networks :
    k => v
    if v.router.use_existing
  }

  name = each.value.router.name
}

########################################
# Resolve Router IDs
########################################
locals {
  router_ids = {
    for k, v in var.networks :
    k => (
      v.router.create ?
      openstack_networking_router_v2.routers[k].id :
      v.router.use_existing ?
      data.openstack_networking_router_v2.existing_routers[k].id :
      null
    )
  }
}

########################################
# Create Networks
########################################
resource "openstack_networking_network_v2" "networks" {
  for_each = var.networks
  name     = each.key
  shared   = true
}

########################################
# Flatten Subnets (PLAN-TIME SAFE)
########################################
locals {
  subnets = merge([
    for net_name, net in var.networks : {
      for subnet_name, subnet in net.subnets :
      "${net_name}.${subnet_name}" => {
        network        = net_name
        cidr           = subnet.cidr
        gateway        = subnet.gateway
        dns            = subnet.dns
        dhcp           = subnet.dhcp

        attach_router  = net.router.create || net.router.use_existing
      }
    }
  ]...)
}

########################################
# Create Subnets
########################################
resource "openstack_networking_subnet_v2" "subnets" {
  for_each = local.subnets

  name            = each.key
  network_id      = openstack_networking_network_v2.networks[each.value.network].id
  cidr            = each.value.cidr
  gateway_ip      = each.value.gateway
  dns_nameservers = each.value.dns
  enable_dhcp     = each.value.dhcp
  ip_version      = 4
}

########################################
# Attach Subnets to Routers (SAFE)
########################################
resource "openstack_networking_router_interface_v2" "interfaces" {
  for_each = {
    for k, v in local.subnets :
    k => v
    if v.attach_router
  }

  router_id = local.router_ids[each.value.network]
  subnet_id = openstack_networking_subnet_v2.subnets[each.key].id
}


########################################
# Save the Output
########################################
resource "local_file" "terraform_outputs_hcl" {
  filename = "/home/jack/openstack/openstack-network1/infra-network.json"

  content = <<EOF
network_ids = {
${join("\n", [
  for k, v in openstack_networking_network_v2.networks :
  "  \"${k}\" = \"${v.id}\""
])}
}

router_ids = {
${join("\n", [
  for k, v in local.router_ids :
  v != null ? "  \"${k}\" = \"${v}\"" : null
])}
}

subnet_ids = {
${join("\n", [
  for k, v in openstack_networking_subnet_v2.subnets :
  "  \"${k}\" = \"${v.id}\""
])}
}
EOF


  lifecycle {
    ignore_changes = [content]
  }
}
