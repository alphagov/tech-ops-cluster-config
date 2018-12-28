terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "danielblair.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

module "gsp-cluster" {
    source = "git::https://github.com/alphagov/gsp-terraform-ignition//modules/gsp-cluster?ref=initial-import"
    cluster_name = "${var.cluster_name}"
    cluster_id = "danielblair.run-sandbox.aws.ext.govsvc.uk"
    dns_zone_id = "Z23SW7QP3LD4TS"
    dns_zone = "run-sandbox.aws.ext.govsvc.uk"
    user_data_bucket_name = "${var.user_data_bucket_name}"
    user_data_bucket_region = "${var.user_data_bucket_region}"
    k8s_tag = "${var.k8s_tag}"
    admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-release" {
  source = "../../modules/github-flux"

  namespace      = "gsp-base"
  chart_git      = "https://github.com/alphagov/gsp-base.git"
  chart_ref      = "ignition"
  chart_path     = "charts/base"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "danielblair.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-monitoring-release" {
  source = "../../modules/github-flux"

  namespace      = "monitoring-system"
  chart_git      = "https://github.com/alphagov/gsp-monitoring.git"
  chart_ref      = "master"
  chart_path     = "monitoring"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "danielblair.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-canary" {
  source     = "../../modules/canary"
  cluster_id = "danielblair.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-sealed-secrets" {
  source = "../../modules/github-flux"

  namespace      = "secrets-system"
  chart_git      = "https://github.com/alphagov/gsp-sealed-secrets.git"
  chart_ref      = "master"
  chart_path     = "charts/sealed-secrets"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "danielblair.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-ci-system" {
  source = "../../modules/github-flux"

  namespace      = "ci-system"
  chart_git      = "https://github.com/alphagov/gsp-ci-system.git"
  chart_ref      = "add-notary"
  chart_path     = "charts/ci"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "danielblair.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-concourse-ci-pipelines" {
  source = "../../modules/github-flux"

  namespace      = "${module.gsp-ci-system.release-name}-main"
  chart_git      = "https://github.com/alphagov/gsp-ci-pipelines.git"
  chart_ref      = "master"
  chart_path     = "charts/pipelines"
  cluster_name   = "${var.cluster_name}"
  cluster_domain = "danielblair.run-sandbox.aws.ext.govsvc.uk"
}
