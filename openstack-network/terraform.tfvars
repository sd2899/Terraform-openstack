external_network_name = "public1"

networks = {

  Production-Network = {
    router = {
      create        = false
      name          = "test"
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
      monitoring = {
        cidr    = "172.30.6.0/24"
        gateway = "172.30.6.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      security = {
        cidr    = "172.30.7.0/24"
        gateway = "172.30.7.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      backup = {
        cidr    = "172.30.8.0/24"
        gateway = "172.30.8.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      analytics = {
        cidr    = "172.30.9.0/24"
        gateway = "172.30.9.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      app = {
        cidr    = "172.30.10.0/24"
        gateway = "172.30.10.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      db = {
        cidr    = "172.30.11.0/24"
        gateway = "172.30.11.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
      cache = {
        cidr    = "172.30.12.0/24"
        gateway = "172.30.12.1"
        dns     = ["8.8.8.8"]
        dhcp    = true
      }
    }
  }

#  k8s-net = {
#    router = {
#      create        = false
#      name          = "test"
#      use_existing  = true
#      shared_router = true
#    }

#    subnets = {
#      control = {
#        cidr    = "10.20.1.0/24"
#        gateway = "10.20.1.1"
#        dns     = ["8.8.8.8"]
#        dhcp    = true
#      }
#      workers = {
#        cidr    = "10.20.2.0/24"
#        gateway = "10.20.2.1"
#        dns     = ["8.8.8.8"]
#        dhcp    = true
#      }
#    }
#  }

#  storage-net = {
#    router = {
#      create        = false
#      name          = ""
#      use_existing  = false
#      shared_router = false
#    }

#    subnets = {
#      storage = {
#        cidr    = "10.30.1.0/24"
#        gateway = "10.30.1.1"
#        dns     = []
#        dhcp    = false
#      }
#    }
#  }
}
