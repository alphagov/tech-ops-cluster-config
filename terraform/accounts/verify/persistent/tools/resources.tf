module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network?ref=b82ea7b7b8b05a04353c674bf479869a5942a5c2"
  cluster_name = "tools"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent?ref=b82ea7b7b8b05a04353c674bf479869a5942a5c2"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "verify.govsvc.uk"
}
