data "google_client_openid_userinfo" "me" {}

resource "google_compute_firewall" "manager_internal" {
  name        = "${var.cluster_name}-managers-internal"
  description = "mke cluster managers nodes internal traffic"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["2379-2380"]
  }

  source_tags = ["allow-manager"]
}

resource "google_compute_firewall" "manager" {
  name        = "${var.cluster_name}-managers"
  description = "mke cluster managers egress traffic"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["443", "6443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "mke_manager" {
  count        = var.manager_count
  name         = "${var.cluster_name}-manager-${count.index + 1}"
  machine_type = var.manager_type
  metadata = tomap({
    "role"   = "manager"
    ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${var.ssh_key.public_key_openssh}"
  })

  boot_disk {
    initialize_params {
      image = var.image_name
      type  = var.manager_volume_type
      size  = var.manager_volume_size
    }
  }

  #  user_data              = <<EOF
  ##!/bin/bash
  ## Use full qualified private DNS name for the host name.  Kube wants it this way.
  #HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname)
  #echo $HOSTNAME > /etc/hostname
  #sed -i "s|\(127\.0\..\.. *\)localhost|\1$HOSTNAME|" /etc/hosts
  #hostname $HOSTNAME
  #EOF

  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnetwork_name
    access_config {
    }
  }
  tags = [
    "allow-ssh",
    "allow-manager",
    "allow-lb-service-master",
  ]
}

module "load_balancer_master_api" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "~> 2.0.0"
  region       = var.gcp_region
  name         = "${var.cluster_name}-manager-lb"
  service_port = 443
  target_tags  = ["allow-lb-service-master"]
  network      = var.vpc_name
}

module "load_balancer_kube_api" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "~> 2.0.0"
  region       = var.gcp_region
  name         = "${var.cluster_name}-kube-lb"
  service_port = 6443
  target_tags  = ["allow-lb-service-master"]
  network      = var.vpc_name
}