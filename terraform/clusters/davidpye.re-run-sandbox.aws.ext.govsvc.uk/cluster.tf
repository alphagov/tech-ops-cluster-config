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
    key    = "davidpye.re-run-sandbox.aws.ext.govsvc.uk/cluster.tfstate"
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
  cluster_name = "davidpye"
  zone_name    = "run-sandbox.aws.ext.govsvc.uk"
  zone_id      = "Z23SW7QP3LD4TS"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAwibLUDGRloXLKqP1X0GGrsWiseBYQampHi7e2ww/X3q0Q1oGOQxGXm1T0hkdJ2xqBvKejEg1KKcJWn70MLW9lMDyrAtqcyOUsAxa0TjIMnwhlABCj65Yq3VvYY17+9loDR3lWtPRsaS4Rv1y44e1KjVftqj1AFbghRZ62xhzcNLCfWqe9GCffSdkWPDlZxz9JnPy4TnGA90K2b9VFroRpkIgVzex+wINnLV6rrx9Phmbu2A7SDG9iXTQ3kTW0jyAoJcZk/Ymy9stYCRut02tpMKjqgCDO+uPaHGJlRmqhokDpX3kgpQr698IstS0CcTtQV2CYPlkQ8sOkOFxu16Dr0W08j8+qi3ZXX2Ts3U9/CZU5vwKNm+Z1zEpMluEyWkMqiKd9FQHz8eOL3NLOO0SyMbYWlwZnJj2bH5yh0dPcIU7MsEmmzdUFyUaNwbZfQ/+coGf8THOvhtKYSq65kBHD0fhZR7YP6+b7W7WJBfT3+iqMCXFLQgUr7l6Ncy0srX5b8szPe15pSKWHz8eqV8vUcAZu1WJkwudyfhU6qVJYD2+NEIBEg66HE9Jo7kbCUPSe82UoP0FuK7C9Z1ZzgvLZOGngG1DrYH4kif6AokS23+5xrxZevZIjBEoWAzNhD8mBHesacMH+H9PS8I7V4B9HUeWt+YWrVMPnsW9tgfCKQ== davidpye.re-run-sandbox.aws.ext.govsvc.uk"

  admin_role_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"]
}

module "gsp-base-flux-helm" {
  source = "../../modules/github-flux"

  namespace = "gsp-base"
  chart_git  = "https://github.com/alphagov/gsp-base.git"
  chart_ref  = "master"
  chart_path = "charts/base"
  cluster_name = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-monitoring-release" {
  source = "../../modules/github-flux"

  namespace  = "monitoring-system"
  chart_git  = "https://github.com/alphagov/gsp-monitoring.git"
  chart_ref  = "master"
  chart_path = "monitoring"
  cluster_name = "${module.cluster.cluster_name}"
  cluster_domain = "${module.cluster.cluster_name}.${module.cluster.zone_name}"
}

module "gsp-canary" {
  source     = "../../modules/canary"
  cluster_id = "davidpye.run-sandbox.aws.ext.govsvc.uk"
}

module "gsp-sealed-secrets" {
  source = "../../modules/github-flux"

  namespace      = "secrets-system"
  chart_git      = "https://github.com/alphagov/gsp-sealed-secrets.git"
  chart_ref      = "master"
  chart_path     = "charts/sealed-secrets"
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
}
