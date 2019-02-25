module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network?ref=terraform_for_persistent_components"
  cluster_name = "davidmcdonald"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent?ref=terraform_for_persistent_components"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "run-sandbox.aws.ext.govsandbox.uk"
}

module "hsm" {
  source       = "../../../../modules/hsm"
  cluster_name = "davidmcdonald"
  subnet_ids   = "${module.gsp-network.private_subnet_ids}"
}
