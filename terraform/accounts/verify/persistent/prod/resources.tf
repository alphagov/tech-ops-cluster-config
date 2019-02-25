module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network"
  cluster_name = "prod"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "verify.govsvc.uk"
}

module "hsm" {
  source       = "../../../../modules/hsm"
  cluster_name = "${module.gsp-network.cluster-name}"
  subnet_ids   = "${module.gsp-network.private_subnet_ids}"
}
