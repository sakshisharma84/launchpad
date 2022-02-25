data "google_client_openid_userinfo" "me" {}

resource "google_compute_instance" "mke_worker" {
  count = var.worker_count

  name         = "${var.cluster_name}-worker-${count.index + 1}"
  machine_type = var.worker_type
  metadata = tomap({
    "role"   = "worker"
    ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${var.ssh_key.public_key_openssh}"
  })

  boot_disk {
    initialize_params {
      image = var.image_name
      type  = var.worker_volume_type
      size  = var.worker_volume_size
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
    "allow-worker",
  ]
}
