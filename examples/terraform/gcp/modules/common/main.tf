resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "ssh_public_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "ssh_keys/${var.cluster_name}.pem"
  provisioner "local-exec" {
    command = "chmod 0600 ${local_file.ssh_public_key.filename}"
  }
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-1804-lts"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "windows_2019" {
  family  = "windows-2019-for-containers"
  project = "windows-cloud"
}

resource "google_compute_firewall" "common_all_incoming" {
  name        = "${var.cluster_name}-common-all-incoming"
  description = "mke cluster common rule"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "all"
  }

  target_tags   = ["allow-manager", "allow-worker"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "common" {
  name        = "${var.cluster_name}-common-ssh"
  description = "mke cluster common rule"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["allow-ssh"]
  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_firewall" "common_all_outgoing" {
  name        = "${var.cluster_name}-common-all-outgoing"
  description = "mke cluster common rule"
  network     = var.vpc_name
  direction   = "EGRESS"
  allow {
    protocol = "all"
  }
  destination_ranges = ["0.0.0.0/0"]
}