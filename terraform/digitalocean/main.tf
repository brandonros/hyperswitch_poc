terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
    // depends on DIGITALOCEAN_TOKEN
}

resource "digitalocean_ssh_key" "ssh_key" {
  name       = "ssh_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create a new Droplet using the SSH key
resource "digitalocean_droplet" "droplet1" {
  image    = "debian-12-x64"
  name     = "droplet1"
  region   = "nyc3"
  size     = "s-4vcpu-8gb" # 4 vCPU, 8 GB, $48/mo
  ssh_keys = [digitalocean_ssh_key.ssh_key.fingerprint]
}

output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = digitalocean_droplet.droplet1.ipv4_address
}
