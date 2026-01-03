terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

provider "virtualbox" {}

# https://library.tf/providers/terra-farm/virtualbox/latest
resource "virtualbox_vm" "control_plane" {
  name   = "k8s-control-01" # Maybe you want more. Infamous TODO: Add scaling functionality.
  image  = "${path.module}/images/${var.image_name}" # Did I run a security check on this image before using it? No.
  cpus   = 2
  memory = "4096 mib"
  user_data = file("${path.module}/cloud-init.yaml")

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet0"
  }
  
}