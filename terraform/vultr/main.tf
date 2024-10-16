terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
      version = "2.21.0"
    }
  }
}

provider "vultr" {
    # uses VULTR_API_KEY env var
}

resource "vultr_ssh_key" "my_ssh_key" {
  name = "my_ssh_key"
  ssh_key = "${file("~/.ssh/id_ed25519.pub")}"
}

resource "vultr_instance" "my_instance" {
    plan = "vc2-4c-8gb"
    region = "atl"
    os_id = 2136 # bookworm
    hostname = "instance1"
    ssh_key_ids = [resource.vultr_ssh_key.my_ssh_key.id]
    user_data = <<EOF
#cloud-config
users:
  - name: debian
    gecos: "Debian"
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: $6$ovSvGqIVXC9lTasZ$MvCapsQHuQxL1TtJD5BxRczLdeEnCcf6.VGUiy6iYQbWQ1MMsDlcctK39e3um5ebbA0rmyYw4sOjb9KgN3pwx1 # openssl passwd -6
    ssh_authorized_keys:
      - ${file("~/.ssh/id_ed25519.pub")}
EOF
}

output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = vultr_instance.my_instance.main_ip
}
