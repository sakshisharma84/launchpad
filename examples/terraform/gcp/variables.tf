variable "project_name" {
}

variable "cluster_name" {
  default = "mke"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_zone" {
  default = "us-central1-c"
}

variable "gcp_service_credential" {
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

variable "admin_password" {
  default = "dockeradmin"
}

variable "manager_count" {
  default = 1
}

variable "worker_count" {
  default = 3
}

variable "windows_worker_count" {
  default = 0
}

variable "msr_count" {
  default = 0
}

variable "master_type" {
  default = "e2-standard-2"
}

variable "worker_type" {
  default = "e2-standard-2"
}

variable "msr_type" {
  default = "e2-standard-2"
}

variable "manager_volume_type" {
  default = "pd-balanced"
}

variable "manager_volume_size" {
  default = 100
}

variable "worker_volume_size" {
  default = 100
}

variable "msr_volume_size" {
  default = 100
}
variable "windows_administrator_password" {
  default = "w!ndozePassw0rd"
}
