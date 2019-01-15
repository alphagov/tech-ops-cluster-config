terraform {
  backend "s3" {}
}

variable "aws_account_role_arn" {
  type = "string"
}

variable "splunk_hec_url" {
  type = "string"
}

variable "splunk_hec_token" {
  type = "string"
}

variable "persistent_state_bucket_name" {
  type = "string"
}

variable "persistent_state_bucket_key" {
  type = "string"
}

provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn = "${var.aws_account_role_arn}"
  }
}

data "terraform_remote_state" "persistent_state" {
  backend   = "s3"
  workspace = "run-sandbox"

  config {
    bucket = "${var.persistent_state_bucket_name}"
    key    = "${var.persistent_state_bucket_key}"
    region = "eu-west-2"
  }
}

data "aws_caller_identity" "current" {}

module "gsp-cluster" {
  source       = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster?ref=eks-firebreak"
  account_name = "run-sandbox"
  cluster_name = "drb-eks-test"
  dns_zone     = "run-sandbox.aws.ext.govsandbox.uk"

  admin_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/deployer",
  ]

  gds_external_cidrs = [
    "213.86.153.212/32",
    "213.86.153.213/32",
    "213.86.153.214/32",
    "213.86.153.235/32",
    "213.86.153.236/32",
    "213.86.153.237/32",
    "85.133.67.244/32",
    "18.130.144.30/32",  # autom8 concourse
    "3.8.110.67/32",     # autom8 concourse
  ]

  worker_instance_type = "m5.large"
  worker_count         = "2"

  addons = {}

  sealed_secrets_cert_pem        = "${data.terraform_remote_state.persistent_state.sealed_secrets_cert_pem}"
  sealed_secrets_private_key_pem = "${data.terraform_remote_state.persistent_state.sealed_secrets_private_key_pem}"
  vpc_id                         = "${data.terraform_remote_state.persistent_state.vpc_id}"
  private_subnet_ids             = "${data.terraform_remote_state.persistent_state.private_subnet_ids}"
  public_subnet_ids              = "${data.terraform_remote_state.persistent_state.public_subnet_ids}"
  nat_gateway_public_ips         = "${data.terraform_remote_state.persistent_state.nat_gateway_public_ips}"
  splunk_hec_url                 = "${var.splunk_hec_url}"
  splunk_hec_token               = "${var.splunk_hec_token}"
  splunk_index                   = "run_sandbox_k8s"

  codecommit_init_role_arn = "${var.aws_account_role_arn}"
  sre_user_arns            = ["arn:aws:iam::622626885786:user/daniel.blair@digital.cabinet-office.gov.uk"]
  github_client_id         = ""
  github_client_secret     = ""
}

module "prototype-kit" {
  source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/flux-release?ref=eks-firebreak"

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

output "kubeconfig" {
  value = "${module.gsp-cluster.kubeconfig}"
}
