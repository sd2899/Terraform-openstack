external_network_name = "public1"
project_name = "demo"
domain_id    = "default"

networks = {

  Production-Network = {
    router = {
      create        = false
      name          = "demo-terra"
      use_existing  = true
      shared_router = true
    }

    subnets = {
      mgmt = {
        cidr    = "172.30.1.0/24"
        gateway = "172.30.1.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      kubernetes = {
        cidr    = "172.30.2.0/24"
        gateway = "172.30.2.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      developers = {
        cidr    = "172.30.3.0/24"
        gateway = "172.30.3.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      testing = {
        cidr    = "172.30.4.0/24"
        gateway = "172.30.4.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      web = {
        cidr    = "172.30.5.0/24"
        gateway = "172.30.5.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
    }
  }
  k8s-net = {
    router = {
      create        = false
      name          = "demo-terra"
      use_existing  = true
      shared_router = true
    }

    subnets = {
      control = {
        cidr    = "10.70.1.0/24"
        gateway = "10.70.1.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      workers = {
        cidr    = "10.70.2.0/24"
        gateway = "10.70.2.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
    }
  }
}
vms = {
  vm1 = {
    name        = "vm-image"
    flavor     = "m1.small"
    keypair    = "ubuntu"
    security_groups = ["default"]
    #subnet_key = "k8s-net.control"
    ports = [
      {
        network_key   = "k8s-net"
        subnet_key    = "k8s-net.control"
        security_groups = ["default"]
        fixed_ip      = "10.70.1.12"
      },
      {
        network_key   = "Production-Network"
        subnet_key    = "Production-Network.web"
        security_groups = ["default"]
      }
    ]

    user_data_file = "../../scripts/user_data.sh"

    boot = {
      type  = "image"
      image = "ubuntu"
    }
    additional_volumes = [
      { size = 20 }
      #{ size = 50, volume_type = "Default" }
    ]

    assign_fip = true
    #security_group_name = "default"
  }

  vm4 = {
    name        = "vm-image-vol"
    flavor     = "m1.small"
    keypair    = "ubuntu"
    security_groups = ["default"]
    #subnet_key = "k8s-net.control"
    ports = [
      {
        network_key   = "k8s-net"
        subnet_key    = "k8s-net.control"
        security_groups = ["default"]
        fixed_ip      = "10.70.1.20"
      },
      {
        network_key   = "Production-Network"
        subnet_key    = "Production-Network.kubernetes"
        security_groups = ["default"]
      }
    ]

    user_data_file = "../../scripts/user_data.sh"

    boot = {
      type  = "image"
      image = "ubuntu"
      size  = 21
    }
    additional_volumes = [
      { size = 2 },
      { size = 1 }
      #{ size = 50, volume_type = "Default" }
    ]

    assign_fip = false
    #security_group_name = "default"
  }

  vm2 = {
    name        = "vm-volume"
    flavor     = "m1.small"
    keypair    = "ubuntu"
    security_groups = ["default"]
    ports = [
      {
        network_key   = "k8s-net"
        subnet_key    = "k8s-net.workers"
        security_groups = ["default"]
      },
      {
        network_key   = "Production-Network"
        subnet_key    = "Production-Network.mgmt"
        security_groups = ["default"]
        fixed_ip      = "172.30.1.14"
      }
    ]

    #subnet_key = "Production-Network.web"
    user_data_file = "../../scripts/user_data.sh"

    boot = {
      type      = "volume"
      volume_id = "e1c5d1c1-a5e2-46f9-9b1a-ff85a41d1a88"
    }
    additional_volumes = []

    assign_fip = false
    #security_group_name = "default"
  }
  vm3 = {
    name        = "vm-snap"
    flavor     = "m1.small"
    keypair    = "ubuntu"
    security_groups = ["default"]
    ports = [
      {
        network_key   = "Production-Network"
        subnet_key    = "Production-Network.testing"
        security_groups = ["sg"]
      },
      {
        network_key   = "Production-Network"
        subnet_key    = "Production-Network.web"
        security_groups = ["sg"]
      }
    ]

    #subnet_key = "Production-Network.web"
    user_data_file = "../../scripts/user_data.sh"

    boot = {
      type      = "snapshot"
      snapshot_id = "579faa4a-0381-4385-a0ba-40d8cc056eae"
      size        = 82
    }
    additional_volumes = [
      { size = 1 }
    ]

    assign_fip = true
    #security_group_name = "default"
  }
  vm5 = {
    name        = "vm-image1"
    flavor     = "m1.small"
    keypair    = "ubuntu"
    security_groups = ["default"]
    ports = [
      {
        network_key   = "Production-Network"
        subnet_key    = "Production-Network.testing"
        security_groups = ["default"]
      },
      {
        network_key   = "Production-Network"
        subnet_key    = "Production-Network.mgmt"
        security_groups = ["sg"]
      }
    ]

    user_data_file = "../../scripts/user_data.sh"

    boot = {
      type      = "image"
      image = "ubuntu"
      #size        = 82
    }
    additional_volumes = [
      { size = 1 }
    ]

    assign_fip = true
  }

}
