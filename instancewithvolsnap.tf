# ─────────────────────────────
# Terraform provider
# ─────────────────────────────
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

provider "openstack" {
  user_name   = "demo1"
  tenant_name = "demo"
  password    = "1928"
  auth_url    = "http://192.168.123.207:5000"
  region      = "RegionOne"
}

# ─────────────────────────────
# 1️⃣ Base volume from image
# ─────────────────────────────
resource "openstack_blockstorage_volume_v3" "base_volume" {
  name     = "ubuntu-base-volume"
  size     = 20
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

  provisioner "local-exec" {
    when    = "create"
    command = <<EOT
      SNAPSHOT_NAME="ubuntu-base-snapshot"
      VOL_ID=${openstack_blockstorage_volume_v3.base_volume.id}

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
      SNAPSHOT_NAME="ubuntu-base-snapshot"
      if openstack volume snapshot list -f value -c Name | grep -qx "$SNAPSHOT_NAME"; then
        echo "Deleting snapshot $SNAPSHOT_NAME..."
        openstack volume snapshot delete "$SNAPSHOT_NAME"
      else
        echo "Snapshot $SNAPSHOT_NAME not found. Skipping delete."
      fi
    EOT
  }
}

# ─────────────────────────────
# 3️⃣ Wait until snapshot is available
# ─────────────────────────────
resource "null_resource" "wait_for_snapshot_available" {
  depends_on = [null_resource.create_snapshot]

  provisioner "local-exec" {
    command = <<EOT
      SNAPSHOT_NAME="ubuntu-base-snapshot"
      for i in {1..30}; do
        STATUS=$(openstack volume snapshot show $SNAPSHOT_NAME -f value -c status)
        if [ "$STATUS" = "available" ]; then
          echo "Snapshot $SNAPSHOT_NAME is available!"
          exit 0
        fi
        echo "Waiting for snapshot $SNAPSHOT_NAME to become available... ($i/30)"
        sleep 10
      done
      echo "Snapshot $SNAPSHOT_NAME did not become available in time!"
      exit 1
    EOT
  }
}

# ─────────────────────────────
# 4️⃣ Reference snapshot
# ─────────────────────────────
data "openstack_blockstorage_snapshot_v3" "ubuntu_snapshot" {
  name       = "ubuntu-base-snapshot"
  depends_on = [null_resource.wait_for_snapshot_available]
}

# ─────────────────────────────
# 5️⃣ Boot volumes from snapshot
# ─────────────────────────────
variable "vm_names" {
  type    = list(string)
  default = ["web1", "web2"]
}

resource "openstack_blockstorage_volume_v3" "boot_volumes" {
  for_each    = toset(var.vm_names)
  name        = "${each.key}-boot-volume"
  size        = 20
  snapshot_id = data.openstack_blockstorage_snapshot_v3.ubuntu_snapshot.id
  #bootable    = true

  timeouts {
    create = "10m"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# ─────────────────────────────
# 6️⃣ Launch compute instances from boot volumes
# ─────────────────────────────
resource "openstack_compute_instance_v2" "instances" {
  for_each        = toset(var.vm_names)
  name            = each.key
  flavor_name     = "m1.medium"
  key_pair        = "ubuntu"
  security_groups = ["default"]

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.boot_volumes[each.key].id
    source_type           = "volume"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true   # ✅ Auto-delete boot volumes when instance is destroyed
  }

  network {
    name = "demo"
  }

  depends_on = [openstack_blockstorage_volume_v3.boot_volumes]
}

# ─────────────────────────────
# 7️⃣ Output VM IPs
# ─────────────────────────────
output "vm_ips" {
  value = { for name, vm in openstack_compute_instance_v2.instances : name => vm.access_ip_v4 }
}

# ─────────────────────────────
# 8️⃣ Image ID variable
# ─────────────────────────────
variable "image_id" {
  description = "OpenStack image ID for Ubuntu Desktop"
  type        = string
}
