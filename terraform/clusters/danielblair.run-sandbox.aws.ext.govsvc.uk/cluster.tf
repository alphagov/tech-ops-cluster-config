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
    ssh_authorized_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhje7LMEsP8/2HFBQHvGbwAVRzUuNuVZJhVjHRoZxvARg1nn9D1bWx0FnK9aWL7cmu89P8pQiWGBEjWWZzHjZWnFJ4d5hu+oJliRySbhskiuVCSgP3Z0Grx/Q4cJu35O1LkwcVi8ZbYk/Ud+5pHa/U6i8bYcvxSVb2bEY9Q2t8dF9ev1aSRNNaOj7Y+2aenAwPo9Whr4DryVrAjI/CC7phv6SOSJ4o9y5Ro3Z9yEfy42wOOEL2+Q/6j9dWMVGyuaZkJ9eXRAeRHkcpuUs/kDR07bMBUolz9tfaMZWNtGgeEgm/r39fnvs1B08Pv0sHeYxh1QrNhzG076lhSVuTzxzPYplehgZNeOVseotQHRufsVMXH5paAIMgkXISUHF1dnX4U/7biSldiCG1JNvFCcTTLTEtsPC0H8Hxt5PEr8vVe4Tdfk6KVjZOVdi1alOiDyw4O8jdNKrM8gDE83tG++/RRptxu4pBvdX65AnQeocsA8S4l9hLdB76duQYAjF6iV37rheioOj9jPJR4wi8zajeNnyDbxC5B12I7Pnqz6DQvQkvADK6x27dA6mAVIqq6ORXCXENjh8W/n+9Math2l07csnjzi67np/8a9Gn01LT9xr/xFZgY+ztnHRtDSnxXfKEx3IpOvgfmP6qan3nAIMVmfkcSWd9tnC1m+qQDy/nNQ== daniel.blair@digital.cabinet-office.gov.uk"]
    user_data_bucket_name = "${var.user_data_bucket_name}"
    user_data_bucket_region = "${var.user_data_bucket_region}"
    k8s_tag = "${var.k8s_tag}"
    admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-release" {
  source = "../../modules/github-flux"

  namespace      = "gsp-base"
  chart_git      = "https://github.com/alphagov/gsp-base.git"
  chart_ref      = "master"
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
