terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.52.1"
    }
  }
}

###############################################
# NETWORK LOOKUPS
###############################################
data "openstack_networking_network_v2" "existing" {
  name = var.network_name
}

data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

###############################################
# BOOT VOLUME CREATION (snapshot / clone)
###############################################
resource "openstack_blockstorage_volume_v3" "boot_volumes" {
  for_each = {
    for key, vm in var.vms : key => vm
    if try(vm.boot_snapshot_id, null) != null ||
       try(vm.source_volume_id, null) != null
  }

  name          = "${each.value.name}-boot-volume"
  size          = lookup(each.value, "boot_volume_size", 50)
  description   = "Boot volume for ${each.value.name}"
  snapshot_id   = lookup(each.value, "boot_snapshot_id", null)
  source_vol_id = lookup(each.value, "source_volume_id", null)
  volume_type   = lookup(each.value, "volume_type", null)
}

###############################################
# MULTIPLE DATA VOLUMES PER VM
###############################################
locals {
  data_volumes_flat = merge([
    for vm_key, vm in var.vms : {
      for idx, cfg in try(vm.data_volumes, []) :
      "${vm_key}-${idx}" => {
        vm_key      = vm_key
        vm_name     = vm.name
        vol_idx     = idx
        size        = cfg.size
        description = try(cfg.description, "Data volume ${idx} for ${vm.name}")
        volume_type = try(cfg.volume_type, null)
        device      = try(cfg.device, null)
      }
    }
  ]...)
}

resource "openstack_blockstorage_volume_v3" "data_volumes" {
  for_each = local.data_volumes_flat

  name        = "${each.value.vm_name}-data-${each.value.vol_idx}"
  size        = each.value.size
  description = each.value.description
  volume_type = each.value.volume_type

  lifecycle {
    ignore_changes = [size]
  }
}

###############################################
# VM CREATION
###############################################
resource "openstack_compute_instance_v2" "vms" {
  for_each = var.vms

  name        = each.value.name
  flavor_name = each.value.flavor
  key_pair    = coalesce(each.value.keypair, var.default_keypair)

  security_groups = each.value.security_groups

  # Image ONLY when NOT booting from volume
  image_name = (
    try(each.value.boot_volume_id, null) != null ||
    try(each.value.boot_snapshot_id, null) != null ||
    try(each.value.source_volume_id, null) != null
  ) ? null : each.value.image

  network { uuid = data.openstack_networking_network_v2.existing.id }

  user_data = file(
    coalesce(each.value.user_data_file, var.default_user_data_file)
  )

  metadata = { environment = var.environment }

  # Boot from existing volume
  dynamic "block_device" {
    for_each = try(each.value.boot_volume_id, null) != null ? [1] : []
    content {
      uuid                  = each.value.boot_volume_id
      source_type           = "volume"
      destination_type      = "volume"
      boot_index            = 0
      delete_on_termination = false
    }
  }

  # Boot from newly created boot volume (snapshot/clone)
  dynamic "block_device" {
    for_each = (
      try(each.value.boot_snapshot_id, null) != null ||
      try(each.value.source_volume_id, null) != null
    ) ? [1] : []
    content {
      uuid                  = openstack_blockstorage_volume_v3.boot_volumes[each.key].id
      source_type           = "volume"
      destination_type      = "volume"
      boot_index            = 0
      delete_on_termination = lookup(each.value, "delete_boot_volume_on_termination", false)
    }
  }

  lifecycle {
    ignore_changes = [
      user_data,
      image_name,
      image_id,
    ]
  }

  depends_on = [
    openstack_blockstorage_volume_v3.boot_volumes
  ]
}

###############################################
# ATTACH DATA VOLUMES
###############################################
resource "openstack_compute_volume_attach_v2" "attach_data" {
  for_each = local.data_volumes_flat

  instance_id = openstack_compute_instance_v2.vms[each.value.vm_key].id
  volume_id   = openstack_blockstorage_volume_v3.data_volumes[each.key].id
  device      = each.value.device
}

###############################################
# FLOATING IP MANAGEMENT
###############################################
resource "openstack_networking_floatingip_v2" "fips" {
  for_each = {
    for key, vm in var.vms : key => vm
    if try(vm.assign_fip, false)
  }
  pool = data.openstack_networking_network_v2.external.name
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  for_each = {
    for key, vm in var.vms : key => vm
    if try(vm.assign_fip, false)
  }

  floating_ip = openstack_networking_floatingip_v2.fips[each.key].address
  instance_id = openstack_compute_instance_v2.vms[each.key].id
}
