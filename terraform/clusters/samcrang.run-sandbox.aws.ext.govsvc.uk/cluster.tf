provider "aws" {
  region  = "eu-west-2"
  version = "~> 1.41"
  alias   = "default"
}

provider "local" {
  version = "~> 1.0"
  alias   = "default"
}

provider "null" {
  version = "~> 1.0"
  alias   = "default"
}

provider "template" {
  version = "~> 1.0"
  alias   = "default"
}

provider "tls" {
  version = "~> 1.0"
  alias   = "default"
}

terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "samcrang.run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
  }
}

data "aws_caller_identity" "current" {}

module "cluster" {
  source = "../../modules/gsp-cluster"

  providers = {
    aws      = "aws.default"
    local    = "local.default"
    null     = "null.default"
    template = "template.default"
    tls      = "tls.default"
  }

  # AWS
  cluster_name = "samcrang"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPoK08iEmu1p7yPpSdDkWOEUfznDwJemMyKRJOtU1s2EuAIZtgr+jC5OfR7jcsxs1GdbB31qHnmKh6i2VmxgPFmuNqmlpf/iLxBKLEmzOP1b81QzizrRZH2Ir4f1T8ucIBTZK1Yjdr0J6lL1YTXAz2iU33K8qw93M9UpMTkb8QQYDuLKf3IE4efLf8O2GE7acne9uWpiIyQYXx+CPL95yCDpzRc8XQfW0XpFDjK+eVNgfrAAi3PXv2Nt98JEJhHmHFxI6nQCU1vTABTS7f+bMfqROjTj3kGDCO4eWqs820JSbFuWVGJi/e5BRoO1IjRHGI9Cp1OozagWHlZAX15EVosiBXCYvOqGCr3EeBnV2pHnhYR7r+ThZWnJ8okrviDEAd5zan5b1sI8mdHX2QDIXvN4cSRqFQrcNuiTaPRQJEobfy1abi2B2kjlu47x+KCdNZoJTopf3HXcq/3qBV6fBgfT3QOZLL4jX5gHRT55vTNrgFi7eqsqO3hR2HwGd9bwC+UGwUeDn+bB6zUP3W0hKfbIe34x2+VsLav+c8ef6j1IBNd6P0Hfdm5RArCOdQ3pt6GXtYHetE6mrWIe+P2N+Imv/zS41m1X9+/Gzo74N26UGVl9EdbKmlD8/PbQkAT34dvZO2TfMoqg0eFtqTmAPYwXsp7fkEV+Rzsty1Qnxwmw== samcrang.run-sandbox.aws.ext.govsvc.uk"

  admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-flux-helm" {
  source = "../../modules/github-flux"

  namespace = "gsp-base"
  chart_git  = "https://github.com/alphagov/gsp-base.git"
  chart_ref  = "master"
  chart_path = "charts/base"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-monitoring-release" {
  source = "../../modules/github-flux"

  namespace  = "monitoring-system"
  chart_git  = "https://github.com/alphagov/gsp-monitoring.git"
  chart_ref  = "master"
  chart_path = "monitoring"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-canary" {
  source     = "../../modules/canary"
  cluster_id = "samcrang.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-sealed-secrets" {
  source = "../../modules/github-flux"

  namespace  = "secrets-system"
  chart_git  = "https://github.com/alphagov/gsp-sealed-secrets.git"
  chart_ref  = "master"
  chart_path = "charts/sealed-secrets"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-ci-system" {
  source = "../../modules/github-flux"
  namespace      = "ci-system"
  chart_git      = "https://github.com/alphagov/gsp-ci-system.git"
  chart_ref      = "master"
  chart_path     = "charts/ci"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-concourse-ci-pipelines" {
  source = "../../modules/github-flux"
  namespace      = "${module.gsp-ci-system.release-name}-main"
  chart_git      = "https://github.com/alphagov/gsp-ci-pipelines.git"
  chart_ref      = "master"
  chart_path     = "charts/pipelines"
  cluster_name   = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
  values = <<HEREDOC
    ecr:
      registry: ${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-2.amazonaws.com
      region: eu-west-2
HEREDOC
}
