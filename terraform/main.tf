terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

provider "virtualbox" {}

# ─────────────────────────────────────────────
# ticket01 — osTicket Ticketing System
# IP: 192.168.56.105
# ─────────────────────────────────────────────
resource "virtualbox_vm" "ticket01" {
  name   = "ticket01"
  image  = var.ticket01_ova
  cpus   = 1
  memory = "2048 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = "VirtualBox Host-Only Ethernet Adapter"
  }

  network_adapter {
    type = "nat"
  }
}
