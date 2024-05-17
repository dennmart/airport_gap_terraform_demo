terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.46.1"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_cloud_api_token
}

data "hcloud_ssh_key" "airport_gap_ssh_key" {
  name = "Airport Gap Deploy Key"
}

resource "hcloud_firewall" "web_server_and_ssh" {
  name = "Web Server and SSH"

  rule {
    description = "Allow HTTP traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "Allow HTTPS traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "Allow SSH traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_network" "airport_gap_private_network" {
  name     = "Airport Gap Private Network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "airport_gap_private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.airport_gap_private_network.id
  network_zone = "us-west"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_server" "airport_gap" {
  name         = "airportgap"
  server_type  = "cpx21"
  location     = "hil"
  image        = "ubuntu-22.04"
  ssh_keys     = [data.hcloud_ssh_key.airport_gap_ssh_key.id]
  firewall_ids = [hcloud_firewall.web_server_and_ssh.id]

  network {
    network_id = hcloud_network.airport_gap_private_network.id
  }

  depends_on = [
    hcloud_network_subnet.airport_gap_private_network_subnet
  ]
}
