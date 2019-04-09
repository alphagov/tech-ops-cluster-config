module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network?ref=eks-firebreak"
  cluster_name = "${var.cluster_name}"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent?ref=eks-firebreak"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "${var.dns_zone}"
}
