module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network?ref=6bd87446ae528e07c63f2e84c95a712e5c6b3864"
  cluster_name = "tools"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent?ref=6bd87446ae528e07c63f2e84c95a712e5c6b3864"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "verify.govsvc.uk"
}
