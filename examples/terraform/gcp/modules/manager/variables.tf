variable "gcp_region" {}

variable "cluster_name" {}

variable "vpc_name" {}

variable "subnetwork_name" {}

variable "image_name" {}

variable "ssh_key" {}

variable "manager_count" {
  default = 3
}

variable "manager_type" {
  default = "e2-standard-2"
}

variable "manager_volume_type" {
  default = "pd-balanced"
}

variable "manager_volume_size" {
  default = 100
}
