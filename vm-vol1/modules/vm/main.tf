locals {
  # Convert flavor_name to a list (works for both single string and list inputs)
  flavor_list = flatten([
    try(
      tolist(var.flavor_name),
      [var.flavor_name]
    )
  ])
}

# 1️⃣ Get image details
data "openstack_images_image_v2" "image" {
  name = var.image_name
}

# 2️⃣ Create base volume from image
resource "openstack_blockstorage_volume_v3" "base_volume" {
  name     = "${var.os_name}-base-volume"
  size     = var.volume_size
  image_id = data.openstack_images_image_v2.image.id

  timeouts {
    create = "20m"
  }
}

# 3️⃣ Create snapshot (only if more than one VM)
resource "null_resource" "create_snapshot" {
  count = var.vm_count > 1 ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      SNAPSHOT_NAME="${var.os_name}-base-snapshot"
      VOL_ID=${openstack_blockstorage_volume_v3.base_volume.id}
      STATUS=$(openstack volume snapshot list -f value -c Name | grep -x "$SNAPSHOT_NAME" || true)
      if [ -z "$STATUS" ]; then
        openstack volume snapshot create --volume $VOL_ID --name $SNAPSHOT_NAME
      fi
    EOT
  }


  # Cleanup snapshot on destroy
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

# wait for snapshot to become available
resource "null_resource" "wait_snapshot_available" {
  count = var.vm_count > 1 ? 1 : 0
  depends_on = [null_resource.create_snapshot]

  provisioner "local-exec" {
    command = <<EOT
      SNAPSHOT_NAME="${var.os_name}-base-snapshot"
      for i in {1..30}; do
        STATUS=$(openstack volume snapshot show $SNAPSHOT_NAME -f value -c status)
        if [ "$STATUS" = "available" ]; then
          echo "Snapshot is ready!"
          exit 0
        fi
        echo "Waiting for snapshot... ($i/30)"
        sleep 10
      done
      echo "Snapshot did not become available in time!"
      exit 1
    EOT
  }
}


# 4️⃣ Get snapshot info (only if snapshot created)
#data "openstack_blockstorage_snapshot_v3" "snapshot" {
#  name       = "${var.os_name}-base-snapshot"
#  depends_on = [null_resource.wait_snapshot_available]
#}

data "openstack_blockstorage_snapshot_v3" "snapshot" {
  count     = var.vm_count > 1 ? 1 : 0
  name      = "${var.os_name}-base-snapshot"
  volume_id = openstack_blockstorage_volume_v3.base_volume.id
}

# 5️⃣ Create compute instances
resource "openstack_compute_instance_v2" "vms" {
  count = var.vm_count

  name        = "${var.os_name}-vm-${count.index + 1}"
  flavor_name = local.flavor_list[count.index]
  key_pair    = var.keypair_name

  network {
    uuid = var.network_id
  }

  block_device {
    uuid                  = count.index == 0 ? openstack_blockstorage_volume_v3.base_volume.id : data.openstack_blockstorage_snapshot_v3.snapshot[0].id
    source_type           = count.index == 0 ? "volume" : "snapshot"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }
}

data "openstack_networking_port_v2" "vm_port" {
  count      = var.vm_count
  device_id  = openstack_compute_instance_v2.vms[count.index].id
}

#  6️⃣ Assign floating IPs (optional, uncomment if needed)
 resource "openstack_networking_floatingip_v2" "fips" {
   count = var.vm_count
   pool  = "public1"
 }

 resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
   count       = var.vm_count
   floating_ip = openstack_networking_floatingip_v2.fips[count.index].address
   port_id     = data.openstack_networking_port_v2.vm_port[count.index].id
 }

# 7️⃣ Delete volume after destroy
resource "null_resource" "delete_volume" {
  triggers = {
    volume_id = openstack_blockstorage_volume_v3.base_volume.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "openstack volume delete ${self.triggers.volume_id} || true"
  }
}

# 8️⃣ Outputs
output "vm_names" {
  value = openstack_compute_instance_v2.vms[*].name
}

output "vm_floating_ips" {
  value = openstack_networking_floatingip_v2.fips[*].address
}
# output "vm_ips" {
#   value = openstack_networking_floatingip_v2.fips[*].address
# }
root@test-terra:/home/tera# cat openstack/terraform/vm-vol11/modules/vm/main.tf
locals {
  # Convert flavor_name to a list (works for both single string and list inputs)
  flavor_list = flatten([
    try(
      tolist(var.flavor_name),
      [var.flavor_name]
    )
  ])
}

# 1️⃣ Get image details
data "openstack_images_image_v2" "image" {
  name = var.image_name
}

# 2️⃣ Create base volume from image
resource "openstack_blockstorage_volume_v3" "base_volume" {
  name     = "${var.os_name}-base-volume"
  size     = var.volume_size
  image_id = data.openstack_images_image_v2.image.id

  timeouts {
    create = "20m"
  }
}

# 3️⃣ Create snapshot (only if more than one VM)
resource "null_resource" "create_snapshot" {
  count = var.vm_count > 1 ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      SNAPSHOT_NAME="${var.os_name}-base-snapshot"
      VOL_ID=${openstack_blockstorage_volume_v3.base_volume.id}
      STATUS=$(openstack volume snapshot list -f value -c Name | grep -x "$SNAPSHOT_NAME" || true)
      if [ -z "$STATUS" ]; then
        echo "Creating snapshot $SNAPSHOT_NAME..."
        openstack volume snapshot create --volume $VOL_ID --name $SNAPSHOT_NAME
      fi
    EOT
  }


  # Cleanup snapshot on destroy
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

# wait for snapshot to become available
#resource "null_resource" "wait_snapshot_available" {
#  count = var.vm_count > 1 ? 1 : 0
#  depends_on = [null_resource.create_snapshot]

#  provisioner "local-exec" {
#    command = <<EOT
#      SNAPSHOT_NAME="${var.os_name}-base-snapshot"
#     for i in {1..30}; do
#        STATUS=$(openstack volume snapshot show $SNAPSHOT_NAME -f value -c status)
#        if [ "$STATUS" = "available" ]; then
#          echo "Snapshot is ready!"
#          exit 0
#        fi
#        echo "Waiting for snapshot... ($i/30)"
#        sleep 10
#      done
#      echo "Snapshot did not become available in time!"
#      exit 1
#    EOT
#  }
#}

# 4️⃣ Get snapshot info (Now depends on the null_resource completing)
data "openstack_blockstorage_snapshot_v3" "snapshot" {
  count       = var.vm_count > 1 ? 1 : 0
  name        = "${var.os_name}-base-snapshot"
  most_recent = true

  # CRITICAL: Forces Terraform to run the null_resource first
  # before trying to fetch the snapshot data.
  depends_on  = [null_resource.create_snapshot]
}

# 5️⃣ Create compute instances
resource "openstack_compute_instance_v2" "vms" {
  count = var.vm_count

  name        = "${var.os_name}-vm-${count.index + 1}"
  flavor_name = local.flavor_list[count.index]
  key_pair    = var.keypair_name

  network {
    uuid = var.network_id
  }

  block_device {
    uuid                  = count.index == 0 ? openstack_blockstorage_volume_v3.base_volume.id : data.openstack_blockstorage_snapshot_v3.snapshot[0].id
    source_type           = count.index == 0 ? "volume" : "snapshot"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }
}

data "openstack_networking_port_v2" "vm_port" {
  count      = var.vm_count
  device_id  = openstack_compute_instance_v2.vms[count.index].id
}

#  6️⃣ Assign floating IPs (optional, uncomment if needed)
 resource "openstack_networking_floatingip_v2" "fips" {
   count = var.vm_count
   pool  = "public1"
 }

 resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
   count       = var.vm_count
   floating_ip = openstack_networking_floatingip_v2.fips[count.index].address
   port_id     = data.openstack_networking_port_v2.vm_port[count.index].id
 }

# 7️⃣ Delete volume after destroy
resource "null_resource" "delete_volume" {
  triggers = {
    volume_id = openstack_blockstorage_volume_v3.base_volume.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "openstack volume delete ${self.triggers.volume_id} || true"
  }
}

# 8️⃣ Outputs
output "vm_names" {
  value = openstack_compute_instance_v2.vms[*].name
}

output "vm_floating_ips" {
  value = openstack_networking_floatingip_v2.fips[*].address
}
# output "vm_ips" {
#   value = openstack_networking_floatingip_v2.fips[*].address
# }

root@test-terra:/home/tera# cat openstack/terraform/vm-vol11/modules/vm/main.tf
locals {
  # Convert flavor_name to a list (works for both single string and list inputs)
  flavor_list = flatten([
    try(
      tolist(var.flavor_name),
      [var.flavor_name]
    )
  ])
}

locals {
  base_name = "${var.os_name}-vm"
}

# 1️⃣ Get image details
data "openstack_images_image_v2" "image" {
  name = var.image_name
}

# 2️⃣ Create base volume from image
resource "openstack_blockstorage_volume_v3" "base_volume" {
  name     = "${var.os_name}-base-volume"
  size     = var.volume_size
  image_id = data.openstack_images_image_v2.image.id

  timeouts {
    create = "20m"
  }
}


# Step 2️⃣ Snapshot Creation (via CLI)
resource "null_resource" "create_snapshot" {
  count = var.vm_count > 1 ? 1 : 0

  triggers = {
    volume_id     = openstack_blockstorage_volume_v3.base_volume.id
    snapshot_name = "${local.base_name}-snapshot"
  }

  provisioner "local-exec" {
    command = <<EOT
      openstack volume snapshot create --force --volume ${self.triggers.volume_id} ${self.triggers.snapshot_name}
    EOT
  }
}

# Step 3️⃣ Wait for Snapshot
data "openstack_blockstorage_snapshot_v3" "snapshot" {
  count = var.vm_count > 1 ? 1 : 0

  depends_on = [null_resource.create_snapshot]
  name       = "${local.base_name}-snapshot"
}

# Step 4️⃣ Create Volumes for All VMs
#resource "openstack_blockstorage_volume_v3" "vm_volumes" {
#  count = var.vm_count

#  name = "${local.base_name}-${count.index}-volume"
  #size = 20

#  image_id    = var.vm_count == 1 ? var.image_name : null
#  snapshot_id = var.vm_count > 1 && count.index > 0 ? data.openstack_blockstorage_snapshot_v3.snapshot[0].id : null

#  lifecycle {
#    prevent_destroy = false
#  }
#}

# 5️⃣ Create compute instances
resource "openstack_compute_instance_v2" "vms" {
  count = var.vm_count

  name        = "${var.os_name}-vm-${count.index + 1}"
  flavor_name = local.flavor_list[count.index]
  key_pair    = var.keypair_name

  network {
    uuid = var.network_id
  }

  block_device {
    uuid                  = count.index == 0 ? openstack_blockstorage_volume_v3.base_volume.id : data.openstack_blockstorage_snapshot_v3.snapshot[0].id
    source_type           = count.index == 0 ? "volume" : "snapshot"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }
}

data "openstack_networking_port_v2" "vm_port" {
  count      = var.vm_count
  device_id  = openstack_compute_instance_v2.vms[count.index].id
}

#  6️⃣ Assign floating IPs (optional, uncomment if needed)
 resource "openstack_networking_floatingip_v2" "fips" {
   count = var.vm_count
   pool  = "public1"
 }

 resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
   count       = var.vm_count
   floating_ip = openstack_networking_floatingip_v2.fips[count.index].address
   port_id     = data.openstack_networking_port_v2.vm_port[count.index].id
 }

# 7️⃣ Delete volume after destroy
resource "null_resource" "delete_volume" {
  triggers = {
    volume_id = openstack_blockstorage_volume_v3.base_volume.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "openstack volume delete ${self.triggers.volume_id} || true"
  }
}

# 8️⃣ Outputs
output "vm_names" {
  value = openstack_compute_instance_v2.vms[*].name
}

output "vm_floating_ips" {
  value = openstack_networking_floatingip_v2.fips[*].address
}
# output "vm_ips" {
#   value = openstack_networking_floatingip_v2.fips[*].address
# }
