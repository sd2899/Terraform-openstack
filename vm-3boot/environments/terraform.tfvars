auth_url     = "https://openstack.example.com:5000/v3"
user_name    = "admin"
password     = "SecretPass123"
domain_name  = "default"
project_name = "demo"
region       = "RegionOne"

network_name          = "private-net"
external_network_name = "public-net"

default_keypair = "testkey"

vms = {
  web1 = {
    name        = "web-01"
    flavor      = "m1.small"
    image       = "ubuntu"
    security_groups = ["default"]
    assign_fip = true
    data_volumes = [
      { size = 20 }
    ]
  }

  api1 = {
    name             = "api-01"
    flavor           = "m1.small"
    boot_snapshot_id = "snapshot-uuid"
    security_groups  = ["default"]
    data_volumes = [
      { size = 10 },
      { size = 30 }
    ]
  }

  db1 = {
    name            = "db-01"
    flavor          = "m1.medium"
    source_volume_id = "volume-uuid"
    security_groups = ["default"]
  }
}
