# Mirantis Launchpad Configuration File

Mirantis Launchpad cluster configuration is described in a file that is in YAML format. You can create and modify these files using your favorite text editor. The default name for this file is cluster.yaml, although other file names could be used.

## Configuration File Reference

The complete `cluster.yaml` reference for UCP clusters:

```yaml
apiVersion: launchpad.mirantis.com/v1beta1
kind: UCP
# metadata:
#   name: launchpad-ucp
spec:
  hosts:
  - address: 1.2.1.2
    user: root
    sshPort: 22
    sshKeyPath: ~/.ssh/id_rsa
    privateInterface: eth0
    role: manager
  # - address: 1.3.1.3
  #   user: root
  #   sshKeyPath: ~/.ssh/id_rsa
  #   privateInterface: ens5
  #   role: worker
  # - address: 1.4.1.4
  #   user: docker
  #   sshKeyPath: ~/.ssh/id_rsa
  #   privateInterface: "Ethernet 3"
  #   role: worker
  # ucp:
  #   version: 3.3.0-rc4
  #   imageRepo: "docker.io/docker"
  #   installFlags:
  #   - --admin-username=admin
  #   - --admin-password=orcaorcaorca
  #   configFile: ./ucp-config.toml
  #   configData: |-
  #     [scheduling_configuration]
  #       default_node_orchestrator = "kubernetes"
  # engine:
  #   version: 19.03.8-rc1
  #   channel: test
  #   repoURL: https://repos.mirantis.com
  #   installURL: https://get.mirantis.com/
```
