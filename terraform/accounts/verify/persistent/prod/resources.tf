module "gsp-network" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-network?ref=f248feb275df0f7425d762783ef8fb67e8cccc6b"
  cluster_name = "prod"
}

module "gsp-persistent" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-persistent?ref=f248feb275df0f7425d762783ef8fb67e8cccc6b"
  cluster_name = "${module.gsp-network.cluster-name}"
  dns_zone     = "verify.govsvc.uk"
}

//module "hsm" {
//  source       = "../../../../modules/hsm"
//  cluster_name = "${module.gsp-network.cluster-name}"
//  subnet_ids   = "${module.gsp-network.private_subnet_ids}"
//  subnet_count     = "${module.gsp-network.private-subnet-count}" // https://github.com/hashicorp/terraform/issues/12570
//  splunk_hec_url   = "${var.splunk_hec_url}"
//  splunk_hec_token = "${var.splunk_hec_token}"
//  splunk_index     = "verify_notification_hsm"
//}
