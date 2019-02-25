terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "davidmcdonald.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

# Terraform state that persists between respins of the cluster. This Terraform state contains HSM, sealed secrets, etc.
data "terraform_remote_state" "persistent_state" {
  backend = "s3"

  config {
    bucket = "gds-re-run-sandbox-terraform-state"
    key    = "davidmcdonald.run-sandbox.aws.ext.govsvc.uk/persistent.tfstate"
    region = "eu-west-2"
  }
}

module "gsp-cluster" {
  source                   = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster?ref=terraform_for_persistent_components"
  cluster_name             = "davidmcdonald"
  dns_zone                 = "run-sandbox.aws.ext.govsandbox.uk"
  user_data_bucket_name    = "gds-re-run-sandbox-terraform-state"
  user_data_bucket_region  = "eu-west-2"
  k8s_tag                  = "v1.12.2"
  admin_role_arns          = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
  controller_instance_type = "m5d.large"
  worker_instance_type     = "m5d.large"
  cert_pem                 = "${data.terraform_remote_state.persistent_state.cert_pem}"
  private_key_pem          = "${data.terraform_remote_state.persistent_state.private_key_pem}"
  network_id               = "${data.terraform_remote_state.persistent_state.network_id}"
  private_subnet_ids       = "${data.terraform_remote_state.persistent_state.private_subnet_ids}"
  public_subnet_ids        = "${data.terraform_remote_state.persistent_state.public_subnet_ids}"
  host_cidr                = "${data.terraform_remote_state.persistent_state.host_cidr}"
  nat_gateway_public_ips   = "${data.terraform_remote_state.persistent_state.nat_gateway_public_ips}"

  addons = {
    ingress    = 1
    monitoring = 1
    secrets    = 1
    ci         = 1
    splunk     = 0
  }

  dev_user_arns = [
    "arn:aws:iam::622626885786:user/daniel.blair@digital.cabinet-office.gov.uk",
    "arn:aws:iam::622626885786:user/david.pye@digital.cabinet-office.gov.uk",
    "arn:aws:iam::622626885786:user/david.mcdonald@digital.cabinet-office.gov.uk",
  ]

  dev_namespaces = ["kube-system", "flux-system", "secrets-system"]
}

module "hsm" {
  source       = "../../modules/hsm"
  cluster_name = "davidmcdonald"
  subnet_ids   = "${data.terraform_remote_state.persistent_state.private_subnet_ids}"
}

module "prototype-kit" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release"

  namespace      = "gsp-prototype-kit"
  chart_git      = "https://github.com/alphagov/gsp-govuk-prototype-kit.git"
  chart_ref      = "gsp"
  chart_path     = "charts/govuk-prototype-kit"
  cluster_name   = "${module.gsp-cluster.cluster-name}"
  cluster_domain = "${module.gsp-cluster.cluster-domain-suffix}"
  addons_dir     = "addons/${module.gsp-cluster.cluster-name}"

  values = <<EOF
    ingress:
      hosts:
        - pk.${module.gsp-cluster.cluster-domain-suffix}
        - prototype-kit.${module.gsp-cluster.cluster-domain-suffix}
      tls:
        - secretName: prototype-kit-tls
          hosts:
            - pk.${module.gsp-cluster.cluster-domain-suffix}
            - prototype-kit.${module.gsp-cluster.cluster-domain-suffix}
EOF
}
