data "google_client_openid_userinfo" "me" {}

resource "google_compute_firewall" "worker" {
  name        = "${var.cluster_name}-win-workers"
  description = "mke cluster windows workers"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["5985-5986"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "mke_worker" {
  count = var.worker_count

  name         = "${var.cluster_name}-win-worker-${count.index + 1}"
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
    #source = "${var.cluster_name}-worker-disk-${count.index + 1}"
  }

  lifecycle {
    ignore_changes = []
  }

  metadata_startup_script = <<EOF
<powershell>
$admin = [adsi]("WinNT://./administrator, user")
$admin.psbase.invoke("SetPassword", "${var.windows_administrator_password}")

# Snippet to enable WinRM over HTTPS with a self-signed certificate
# from https://gist.github.com/TechIsCool/d65017b8427cfa49d579a6d7b6e03c93
Write-Output "Disabling WinRM over HTTP..."
Disable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
Disable-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC"
Get-ChildItem WSMan:\Localhost\listener | Remove-Item -Recurse

Write-Output "Configuring WinRM for HTTPS..."
Set-Item -Path WSMan:\LocalHost\MaxTimeoutms -Value '1800000'
Set-Item -Path WSMan:\LocalHost\Shell\MaxMemoryPerShellMB -Value '1024'
Set-Item -Path WSMan:\LocalHost\Service\AllowUnencrypted -Value 'false'
Set-Item -Path WSMan:\LocalHost\Service\Auth\Basic -Value 'true'
Set-Item -Path WSMan:\LocalHost\Service\Auth\CredSSP -Value 'true'

New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP" `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
    -Group "Windows Remote Management" `
    -Program "System" `
    -Protocol TCP `
    -LocalPort "5986" `
    -Action Allow `
    -Profile Domain,Private

New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP-PUBLIC" `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" `
    -Group "Windows Remote Management" `
    -Program "System" `
    -Protocol TCP `
    -LocalPort "5986" `
    -Action Allow `
    -Profile Public

$Hostname = [System.Net.Dns]::GetHostByName((hostname)).HostName.ToUpper()
$pfx = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $Hostname
$certThumbprint = $pfx.Thumbprint
$certSubjectName = $pfx.SubjectName.Name.TrimStart("CN = ").Trim()

New-Item -Path WSMan:\LocalHost\Listener -Address * -Transport HTTPS -Hostname $certSubjectName -CertificateThumbPrint $certThumbprint -Port "5986" -force

Write-Output "Restarting WinRM Service..."
Stop-Service WinRM
Set-Service WinRM -StartupType "Automatic"
Start-Service WinRM
</powershell>
EOF

  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnetwork_name
    access_config {
      #nat_ip = google_compute_address.static.address
    }
  }
  tags = ["worker", "allow-ssh"]
}
