# ─────────────────────────────
# 1️⃣ Base volume from image
# ─────────────────────────────
resource "openstack_blockstorage_volume_v3" "base_volume" {
  name     = "${var.os_name}-base-volume"
  size     = var.volume_size
  image_id = var.image_id

  timeouts {
    create = "20m"
  }
}

# ─────────────────────────────
# 2️⃣ Create snapshot using null_resource
# ─────────────────────────────
resource "null_resource" "create_snapshot" {
  depends_on = [openstack_blockstorage_volume_v3.base_volume]

  # Use triggers for safe dependency injection
  triggers = {
    volume_id   = openstack_blockstorage_volume_v3.base_volume.id
    snapshot_name = "${var.os_name}-base-snapshot"
  }

  provisioner "local-exec" {
    when    = "create"
    command = <<EOT
      SNAPSHOT_NAME=${self.triggers.snapshot_name}
      VOL_ID=${self.triggers.volume_id}

      if ! openstack volume snapshot list -f value -c Name | grep -qx "$SNAPSHOT_NAME"; then
        echo "Creating snapshot $SNAPSHOT_NAME..."
        openstack volume snapshot create --volume $VOL_ID --description "Terraform auto-created base snapshot" $SNAPSHOT_NAME
      else
        echo "Snapshot $SNAPSHOT_NAME already exists. Skipping creation."
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = <<EOT
      SNAPSHOT_NAME=${self.triggers.snapshot_name}
      if openstack volume snapshot list -f value -c Name | grep -qx "$SNAPSHOT_NAME"; then
        echo "Deleting snapshot $SNAPSHOT_NAME..."
        openstack volume snapshot delete $SNAPSHOT_NAME
      else
        echo "Snapshot $SNAPSHOT_NAME not found. Skipping delete."
      fi
    EOT
  }
}

# ─────────────────────────────
# 3️⃣ Wait until Snapshot Available
# ─────────────────────────────
resource "null_resource" "wait_for_snapshot" {
  depends_on = [null_resource.create_snapshot]
  provisioner "local-exec" {
    command = <<EOT
      SNAPSHOT_NAME="${var.os_name}-base-snapshot"
      for i in {1..30}; do
        STATUS=$(openstack volume snapshot show $SNAPSHOT_NAME -f value -c status)
        if [ "$STATUS" = "available" ]; then
          echo "$SNAPSHOT_NAME is ready!"
          exit 0
        fi
        echo "Waiting for $SNAPSHOT_NAME to be available ($i/30)..."
        sleep 10
      done
      echo "Snapshot not ready in time!"
      exit 1
    EOT
  }
}

# ─────────────────────────────
# 4️⃣ Fetch Snapshot
# ─────────────────────────────
data "openstack_blockstorage_snapshot_v3" "base_snapshot" {
  name       = "${var.os_name}-base-snapshot"
  depends_on = [null_resource.wait_for_snapshot]
}

# ─────────────────────────────
# 5️⃣ Create Boot Volumes from Snapshot
# ─────────────────────────────
resource "openstack_blockstorage_volume_v3" "boot_volumes" {
  for_each    = toset(var.vm_names)
  name        = "${each.key}-boot-volume"
  size        = var.volume_size
  snapshot_id = data.openstack_blockstorage_snapshot_v3.base_snapshot.id

  timeouts {
    create = "10m"
  }
}

# ─────────────────────────────
# 6️⃣ Create Instances
# ─────────────────────────────
resource "openstack_compute_instance_v2" "instances" {
  for_each        = toset(var.vm_names)
  name            = each.key
  flavor_name     = var.flavor
  key_pair        = var.keypair
  security_groups = var.security_groups

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.boot_volumes[each.key].id
    source_type           = "volume"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    name = var.network_name
  }
}

resource "openstack_networking_floatingip_v2" "fips" {
  for_each    = toset(var.vm_names)
  pool        = var.external_network
  description = "Floating IP for ${each.key}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  for_each   = toset(var.vm_names)
  floating_ip = openstack_networking_floatingip_v2.fips[each.key].address
  instance_id = openstack_compute_instance_v2.instances[each.key].id
}

# ─────────────────────────────
# 8️⃣ Outputs
# ─────────────────────────────
output "vm_info" {
  value = {
    for name in var.vm_names : name => {
      internal_ip = openstack_compute_instance_v2.instances[name].access_ip_v4
      floating_ip = openstack_networking_floatingip_v2.fips[name].address
    }
  }
}
