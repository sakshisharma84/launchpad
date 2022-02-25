# Network VPC and subnets
resource "google_compute_network" "vpc_network" {
  project                 = var.project_name
  name                    = var.cluster_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1460
}

resource "google_compute_subnetwork" "subnetwork" {
  ip_cidr_range = var.host_cidr
  name          = format("subnet-%s-%s", var.gcp_region, var.cluster_name)
  network       = google_compute_network.vpc_network.id
  region        = var.gcp_region
}