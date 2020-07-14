locals {
  managers = [
    for host in module.managers.machines : {
      address = host.default_ip_address
      user    = "ubuntu" # "TODO: Probably make this a variable"
      role    = "manager"
      privateInterface = "ens5" # Is this supposed to be a constant?
      sshKeyPath = var.ssh_private_key_file
    }
  ]
  workers = [
    for host in module.workers.machines : {
      address = host.default_ip_address
      user    = "ubuntu" # "TODO: Probably make this a variable"
      role    = "worker"
      privateInterface = "ens5" # Is this supposed to be a constant?
      sshKeyPath = var.ssh_private_key_file
    }
  ]
  # workers_windows = [
  #   for host in module.workers_windows.machines : {
  #     address = host.public_ip
  #     user    = "administrator" # "TODO: Probably make this a variable"
  #     role    = "worker"
  #     privateInterface = "Ethernet 2" # Is this supposed to be a constant?
  #     sshKeyPath = var.ssh_private_key_file
  #   }
  # ]
}

output "ucp_cluster" {
  value = {
    apiVersion = "launchpad.mirantis.com/v1beta1"
    kind = "UCP"
    spec = {
      ucp = {
        installFlags: [
          "--admin-username=${var.ucp_admin_username}",
          "--admin-password=${var.ucp_admin_password}",
          "--default-node-orchestrator=kubernetes",
          "--san=${var.ucp_lb_dns_name}",
        ]
      }
      hosts = concat(local.managers, local.workers) #, local.windows_workers)
    }
  }
}
