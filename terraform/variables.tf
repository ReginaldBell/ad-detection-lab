variable "dc01_iso" {
  default = "/path/to/windows-server.iso"
}

variable "dc02_iso" {
  default = "/path/to/windows-server.iso"
}

variable "wkstn01_iso" {
  default = "/path/to/windows-client.iso"
}

variable "siem01_iso" {
  default = "/path/to/ubuntu-server.iso"
}

variable "network_name" {
  default = "enterprise-ad-lab"
}

variable "network_cidr" {
  default = "10.0.0.0/24"
}
