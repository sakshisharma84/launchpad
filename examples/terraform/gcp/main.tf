terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.11.0"
    }
  }
}

provider "google" {
  credentials = var.gcp_service_credential

  project = var.project_name
  region  = var.gcp_region
  zone    = var.gcp_zone
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  cluster_name = var.cluster_name
  host_cidr    = var.vpc_cidr
  gcp_region   = var.gcp_region
}

module "common" {
  source       = "./modules/common"
  project_name = var.project_name
  cluster_name = var.cluster_name
  vpc_name     = module.vpc.vpc_name
}

// Adding SSH Public Key Project Wide
resource "google_compute_project_metadata_item" "ssh-keys" {
  key     = "ssh-keys"
  project = var.project_name
  value   = module.common.ssh_key.public_key_openssh
}

module "managers" {
  source          = "./modules/manager"
  gcp_region      = var.gcp_region
  manager_count   = var.manager_count
  cluster_name    = var.cluster_name
  image_name      = module.common.image_name
  vpc_name        = module.vpc.vpc_name
  subnetwork_name = module.vpc.subnet_name
  ssh_key         = module.common.ssh_key
}

#module "msrs" {
#  source                = "./modules/msr"
#  msr_count             = var.msr_count
#  vpc_id                = module.vpc.id
#  cluster_name          = var.cluster_name
#  subnet_ids            = module.vpc.public_subnet_ids
#  security_group_id     = module.common.security_group_id
#  image_id              = module.common.image_id
#  kube_cluster_tag      = module.common.kube_cluster_tag
#  ssh_key               = var.cluster_name
#  instance_profile_name = module.common.instance_profile_name
#}

module "workers" {
  source          = "./modules/worker"
  worker_count    = var.worker_count
  cluster_name    = var.cluster_name
  vpc_name        = module.vpc.vpc_name
  subnetwork_name = module.vpc.subnet_name
  image_name      = module.common.image_name
  ssh_key         = module.common.ssh_key
  worker_type     = var.worker_type
}

module "windows_workers" {
  source                         = "./modules/windows_worker"
  worker_count                   = var.windows_worker_count
  cluster_name                   = var.cluster_name
  vpc_name                       = module.vpc.vpc_name
  subnetwork_name                = module.vpc.subnet_name
  image_name                     = module.common.windows_2019_image_name
  ssh_key                        = module.common.ssh_key
  worker_type                    = var.worker_type
  windows_administrator_password = var.windows_administrator_password
}

data "google_client_openid_userinfo" "me" {}

locals {
  username = split("@", data.google_client_openid_userinfo.me.email)[0]
}
locals {
  managers = [
    for host in module.managers.machines : {
      ssh = {
        address = host.network_interface.0.access_config.0.nat_ip
        user    = local.username
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.metadata["role"]
      privateInterface = "ens4"
    }
  ]
  #    msrs = [
  #      for host in module.msrs.machines : {
  #        ssh = {
  #          address = host.public_ip
  #          user    = "ubuntu"
  #          keyPath = "./ssh_keys/${var.cluster_name}.pem"
  #        }
  #        role             = host.metadata["role"]
  #        privateInterface = "ens5"
  #      }
  #    ]
  workers = [
    for host in module.workers.machines : {
      ssh = {
        address = host.network_interface.0.access_config.0.nat_ip
        user    = local.username
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.metadata["role"]
      privateInterface = "ens4"
    }
  ]
  windows_workers = [
    for host in module.windows_workers.machines : {
      winRM = {
        address  = host.network_interface.0.access_config.0.nat_ip
        user     = "Administrator"
        password = var.windows_administrator_password
        useHTTPS = true
        insecure = true
      }
      role             = host.metadata["role"]
      privateInterface = "Ethernet 2"
    }
  ]
  mke_launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke"
    spec = {
      mke = {
        adminUsername = "admin"
        adminPassword = var.admin_password
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          #"--san=${module.managers.lb_dns_name}",
        ]
      }
      msr   = {}
      hosts = concat(local.managers, local.workers, local.windows_workers)
      #hosts = concat(local.managers, local.msrs, local.workers, local.windows_workers)
    }
  }


  msr_launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke+msr"
    spec = {
      mke = {
        adminUsername = "admin"
        adminPassword = var.admin_password
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          #"--san=${module.masters.lb_dns_name}",
        ]
      }
      msr = {
        installFlags : [
          "--ucp-insecure-tls",
          #"--dtr-external-url ${module.msrs.lb_dns_name}",
        ]
      }
      hosts = concat(local.managers, local.workers, local.windows_workers)
      #hosts = concat(local.managers, local.msrs, local.workers, local.windows_workers)
    }
  }

  launchpad_tmpl = var.msr_count > 0 ? local.msr_launchpad_tmpl : local.mke_launchpad_tmpl
}


output "mke_cluster" {
  value = yamlencode(local.launchpad_tmpl)
}