terraform {
  required_version = ">= 1.6.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54.1"
    }
  }
}

provider "openstack" {
  # Leave blank to use OpenStack environment variables
  cloud = "open"
  #insecure = true
}
