output "sealed_secrets_cert_pem" {
  description = "Sealed secrets certificate"
  value       = "${module.gsp-persistent.sealed_secrets_cert_pem}"
}

output "sealed_secrets_private_key_pem" {
  description = "Sealed secrets private key"
  value       = "${module.gsp-persistent.sealed_secrets_private_key_pem}"
}

output "private_subnet_ids" {
  value = ["${module.gsp-network.private_subnet_ids}"]
}

output "public_subnet_ids" {
  value = ["${module.gsp-network.public_subnet_ids}"]
}

output "vpc_id" {
  value = "${module.gsp-network.vpc_id}"
}

output "nat_gateway_public_ips" {
  value = ["${module.gsp-network.nat_gateway_public_ips}"]
}

output "host_cidr" {
  description = "CIDR IPv4 range to assign to EC2 nodes"
  value       = "${module.gsp-network.host_cidr}"
}
