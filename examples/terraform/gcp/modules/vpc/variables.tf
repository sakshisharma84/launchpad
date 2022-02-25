variable "cluster_name" {}
variable "project_name" {}
variable "gcp_region" {}

variable "host_cidr" {
  description = "CIDR IPv4 range to assign to GCE nodes"
  default     = "172.31.0.0/16"
}
