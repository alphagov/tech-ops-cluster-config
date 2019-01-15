module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network?ref=eks-firebreak"
  cluster_name = "drb-eks-test"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent?ref=eks-firebreak"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "run-sandbox.aws.ext.govsandbox.uk"
}
