###########################################################
# External Network
###########################################################
data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

###########################################################
# Lookup Security Groups by Name per VM
###########################################################
data "openstack_identity_project_v3" "current" {
  name      = var.project_name
  domain_id = var.domain_id
}

data "openstack_networking_secgroup_v2" "sgs" {
  for_each = toset(flatten([
    for _, vm in var.vms :
    concat(
      try(vm.security_groups, []),
      flatten([for p in try(vm.ports, []) : try(p.security_groups, [])])
    )
  ]))

  name      = each.key
  tenant_id = data.openstack_identity_project_v3.current.id
}

locals {
  sg_ids = {
    for k, v in data.openstack_networking_secgroup_v2.sgs :
    k => v.id
  }
}

#data "openstack_networking_secgroup_v2" "sgs" {
#  for_each = toset(flatten([for _, vm in var.vms : flatten([for p in try(vm.ports, []) : p.security_groups])]))
#  name     = each.key
#  tenant_id = data.openstack_identity_project_v3.current.id
#}

#locals {
#  sg_ids = {
#    for name, sg in data.openstack_networking_secgroup_v2.sgs :
#    name => sg.id
#  }
#}

###########################################################
# Flatten the ports
###########################################################
locals {
  ports_flat = flatten([
    for vm_key, vm in var.vms : [
      for idx, port in try(vm.ports, []) : {
        port_key        = "${vm_key}-${idx}"
        vm_key          = vm_key
        network_key     = port.network_key
        subnet_key      = port.subnet_key
        fixed_ip        = try(port.fixed_ip, null)

        # IMPORTANT
        port_sgs = try(port.security_groups, null)
        vm_sgs   = try(vm.security_groups, [])
      }
    ]
  ])
}

locals {
  primary_port = {
    for vm_key, vm in var.vms :
    vm_key => "${vm_key}-0"
  }
}
#locals {
#  ports_flat = flatten([
#    for vm_key, vm in var.vms : [
#      for idx, port in try(vm.ports, []) : {
#        port_key        = "${vm_key}-${idx}"
#        vm_key          = vm_key
#        network_key     = port.network_key
#        subnet_key      = port.subnet_key
#        security_groups = port.security_groups
#        fixed_ip        = try(port.fixed_ip, null)
#      }
#    ]
#  ])
#}

#locals {
#  primary_port = {
#    for vm_key, vm in var.vms :
#    vm_key => "${vm_key}-0"
#  }
#}

###########################################################
# Create Ports
###########################################################
#resource "openstack_networking_port_v2" "ports" {
#  for_each = { for p in local.ports_flat : p.port_key => p }
#  name       = "${each.value.vm_key}-port-${each.key}"
#  network_id = var.network_ids[each.value.network_key]
#  admin_state_up = true

#  fixed_ip {
#    subnet_id = var.subnet_ids[each.value.subnet_key]
#    ip_address = try(each.value.fixed_ip, null)
#  }

#  port_security_enabled = true

#  security_group_ids = [
#    for sg in each.value.security_groups :
#    local.sg_ids[sg]
#  ]
#  depends_on = [
#    data.openstack_networking_secgroup_v2.sgs
#  ]

#  lifecycle {
#    ignore_changes = [
#      security_group_ids
#    ]
#    precondition {
#      condition     = length(each.value.security_groups) > 0
#      error_message = "Each port must have at least one security group"
#    }
#  }
#}
resource "openstack_networking_port_v2" "ports" {
  for_each = {
    for p in local.ports_flat :
    p.port_key => p
  }

  name       = "${each.value.vm_key}-port-${each.key}"
  network_id = var.network_ids[each.value.network_key]
  admin_state_up = true

  fixed_ip {
    subnet_id  = var.subnet_ids[each.value.subnet_key]
    ip_address = each.value.fixed_ip
  }

  port_security_enabled = true

  security_group_ids = (
    each.value.port_sgs != null && length(each.value.port_sgs) > 0
  ) ? [
    for sg in each.value.port_sgs : local.sg_ids[sg]
  ] : [
    for sg in each.value.vm_sgs : local.sg_ids[sg]
  ]

  lifecycle {
    ignore_changes = [security_group_ids]
  }
}


###########################################################
# Image Lookup (only when needed)
###########################################################
data "openstack_images_image_v2" "images" {
  for_each = toset([
    for _, vm in var.vms :
    vm.boot.image
    if vm.boot.type == "image" && try(vm.boot.size, null) != null
  ])

  name = each.key
}

##########################################################
# volume boot
##########################################################
resource "openstack_blockstorage_volume_v3" "boot" {
  for_each = {
    for k, vm in var.vms :
    k => vm
    if (
      vm.boot.type == "image"    && try(vm.boot.size, null) != null ||
      vm.boot.type == "snapshot" && try(vm.boot.size, null) != null
      #vm.boot.type == "volume"
    )
  }

  name = "${each.key}-boot"

  # REQUIRED for resize-capable volumes
  size = each.value.boot.size
#  size = (
#    each.value.boot.type == "volume"
#    ? null
#    : each.value.boot.size
#  )

  image_id = (
    each.value.boot.type == "image"
    ? data.openstack_images_image_v2.images[each.value.boot.image].id
    : null
  )

  snapshot_id = (
    each.value.boot.type == "snapshot"
    ? each.value.boot.snapshot_id
    : null
  )

  volume_type = try(each.value.boot.volume_type, null)

  enable_online_resize = true

  lifecycle {
    prevent_destroy = false
  }
}

###########################################################
# compute Instances
###########################################################
resource "openstack_compute_instance_v2" "vms" {
  for_each = var.vms

  name        = each.value.name
  flavor_name = each.value.flavor
  key_pair    = each.value.keypair
#  security_groups = []
  security_groups = try(each.value.security_groups, [])

  network {
    port = openstack_networking_port_v2.ports[
      local.primary_port[each.key]
    ].id
  }

  user_data = (
      try(each.value.user_data_file, null) != null
    ) ? file(each.value.user_data_file) : null

#  dynamic "network" {
#    for_each = { for p in local.ports_flat : p.port_key => p if p.vm_key == each.key }

#    content {
#      port = openstack_networking_port_v2.ports[network.key].id
#    }
#  }


  ####################################
  # IMAGE → EPHEMERAL (NO SIZE)
  ####################################
  image_name = (
    each.value.boot.type == "image" &&
    try(each.value.boot.size, null) == null
  ) ? each.value.boot.image : null

  ####################################
  # IMAGE → BOOTABLE VOLUME
  ####################################
  dynamic "block_device" {
    for_each = (
      each.value.boot.type != "image" ||
      try(each.value.boot.size, null) != null
    ) ? [1] : []

    content {
      source_type           = "volume"
      uuid                  = (
        each.value.boot.type == "volume"
        ? each.value.boot.volume_id
        : openstack_blockstorage_volume_v3.boot[each.key].id
      )
      destination_type      = "volume"
      boot_index            = 0
      delete_on_termination = false
    }
  }

  lifecycle {
    ignore_changes = [
      network,
      block_device
    ]
  }


}

####################################################
# Attach Port
####################################################
resource "openstack_compute_interface_attach_v2" "attach" {
  for_each = {
    for p in local.ports_flat :
    p.port_key => p
    if p.port_key != local.primary_port[p.vm_key]
  }

  instance_id = openstack_compute_instance_v2.vms[each.value.vm_key].id
  port_id     = openstack_networking_port_v2.ports[each.key].id

  lifecycle {
    ignore_changes = all
  }
}


#resource "openstack_compute_interface_attach_v2" "attach" {
#  for_each = {
#    for p in local.ports_flat :
#    p.port_key => p
#    if p.port_key != local.primary_port[p.vm_key]
#  }

#  instance_id = openstack_compute_instance_v2.vms[each.value.vm_key].id
#  port_id     = openstack_networking_port_v2.ports[each.key].id

#  lifecycle {
#    prevent_destroy = false
#    ignore_changes  = all
#  }
#}


###########################################################
# Additional Data Volumes
###########################################################
locals {
  extra_volumes = flatten([
    for vm_key, vm in var.vms : [
      for idx, vol in vm.additional_volumes : {
        key         = "${vm_key}-${idx}"
        vm_key      = vm_key
        size        = vol.size
        volume_type = try(vol.volume_type, null)
      }
    ]
  ])
}

resource "openstack_blockstorage_volume_v3" "extra" {
  for_each = { for v in local.extra_volumes : v.key => v }

  name                 = "${each.value.vm_key}-data-${each.key}"
  size                 = each.value.size
  volume_type          = each.value.volume_type
  enable_online_resize = true
}

resource "openstack_compute_volume_attach_v2" "extra_attach" {
  for_each = { for v in local.extra_volumes : v.key => v }

  instance_id = openstack_compute_instance_v2.vms[each.value.vm_key].id
  volume_id   = openstack_blockstorage_volume_v3.extra[each.key].id
}

###########################################################
# Floating IPs (Optional)
###########################################################
resource "openstack_networking_floatingip_v2" "fips" {
  for_each = { for k, v in var.vms : k => v if v.assign_fip }

  pool = data.openstack_networking_network_v2.external.name
}

resource "openstack_compute_floatingip_associate_v2" "assoc" {
  for_each = openstack_networking_floatingip_v2.fips

  floating_ip = each.value.address
  instance_id = openstack_compute_instance_v2.vms[each.key].id
}
