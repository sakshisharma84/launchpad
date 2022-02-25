output "vpc_name" {
  value = google_compute_network.vpc_network.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnetwork.name
}

#output "public_subnet_ids" {
#  value =  aws_subnet.public.*.id
#}


