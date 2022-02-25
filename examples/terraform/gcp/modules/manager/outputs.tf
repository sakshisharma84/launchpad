#output "lb_dns_name" {
#    value = aws_lb.mke_master.dns_name
#}

output "lb_public_ip_address" {
  value = module.load_balancer_master_api.external_ip
}

output "public_ips" {
  value = google_compute_instance.mke_manager.*.network_interface.0.access_config.0.nat_ip
}

output "private_ips" {
  value = google_compute_instance.mke_manager.*.network_interface.0.network_ip
}

output "machines" {
  value = google_compute_instance.mke_manager
}
