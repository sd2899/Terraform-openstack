# Security Group
resource "openstack_networking_secgroup_v2" "vm_sg" {
  name        = "vm-secgroup"
  description = "Allow SSH and ICMP"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_sg.id
}

# Keypair


# Existing Networks
data "openstack_networking_network_v2" "public" {
  name = var.public_network_name
}

data "openstack_networking_network_v2" "private" {
  name = var.private_network_name
}

locals {
  vms_with_fip = var.assign_floating_ip ? var.vms : {}
}

# --- Get Image IDs ---
data "openstack_images_image_v2" "images" {
  for_each = var.vms
  name     = each.value.image
}

# --- Create Boot Volumes ---
resource "openstack_blockstorage_volume_v3" "boot_volumes" {
  for_each = var.vms
  name     = "${each.value.name}-boot"
  size     = each.value.volume_size
  image_id = data.openstack_images_image_v2.images[each.key].id


  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# --- Create Instances ---
resource "openstack_compute_instance_v2" "instances" {
  for_each = var.vms

  name            = each.value.name
  flavor_name     = each.value.flavor
  key_pair        = var.keypair_name
  #security_groups = each.value.security_groups
  security_groups = [openstack_networking_secgroup_v2.vm_sg.name]
  user_data = var.user_data

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.boot_volumes[each.key].id
    source_type           = "volume"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    name = var.private_network_name
  }
}

# --- Create Floating IPs ---
resource "openstack_networking_floatingip_v2" "fips" {
  for_each = local.vms_with_fip
  pool     = var.public_network_name
}

data "openstack_networking_port_v2" "vm_ports" {
  for_each = var.vms
  device_id = openstack_compute_instance_v2.instances[each.key].id
}

# --- Associate Floating IPs ---
resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
  for_each = local.vms_with_fip

  depends_on = [
    openstack_networking_floatingip_v2.fips,
    openstack_compute_instance_v2.instances
  ]

  floating_ip = openstack_networking_floatingip_v2.fips[each.key].address
  port_id     = data.openstack_networking_port_v2.vm_ports[each.key].id
}

# Optionally assign Floating IPs
#resource "openstack_networking_floatingip_v2" "fip" {
#  for_each = var.assign_floating_ip ? local.vm_map : {}
#  pool     = var.public_network_name
#}

#resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
#  for_each      = var.assign_floating_ip ? local.vm_map : {}
#  floating_ip = openstack_networking_floatingip_v2.fip[each.key].id
#  port_id       = openstack_compute_instance_v2.instances[each.key].network[0].port
#}
# 2 Instances
#resource "openstack_compute_instance_v2" "vms" {
  #count       = 1
  #name        = "test-vm-${count.index + 1}"
#  name        = "test-vm"
#  image_name  = var.image
#  flavor_name = var.flavor
#  key_pair    = var.keypair_name

#  security_groups = [openstack_networking_secgroup_v2.vm_sg.name]

#  network {
#    uuid = data.openstack_networking_network_v2.private.id
#  }
#}

# Cinder Volume
#resource "openstack_blockstorage_volume_v3" "volume" {
#  name        = "ter-volume"
#  size        = var.volume_size
#  description = "Volume attached to vm"
#}

# Attach Volume to VM
#resource "openstack_compute_volume_attach_v2" "attach" {
#  instance_id = openstack_compute_instance_v2.vms.id
#  volume_id   = openstack_blockstorage_volume_v3.volume.id
#}


# Floating IPs
#resource "openstack_networking_floatingip_v2" "fips" {
#  count       = 2
#  pool        = var.public_network_name
#  description = "Floating IP for test-vm-${count.index + 1}"
#}

# Associate Floating IPs
#resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
#  count       = 2
#  floating_ip = openstack_networking_floatingip_v2.fips[count.index].address
#  port_id     = openstack_compute_instance_v2.vms[count.index].network[0].port
#  floating_ip = openstack_networking_floatingip_v2.fips.address
#  port_id     = openstack_compute_instance_v2.vms.network[0].port
#}
